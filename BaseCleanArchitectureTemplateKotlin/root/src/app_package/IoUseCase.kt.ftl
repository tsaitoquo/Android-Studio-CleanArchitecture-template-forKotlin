package ${packageName}.utils.commons

import dagger.internal.Preconditions
import io.reactivex.Observable
import io.reactivex.disposables.Disposable
import io.reactivex.disposables.CompositeDisposable
import timber.log.Timber


abstract class IoUseCase<in Q : UseCase.RequestValue, R : UseCase.ResponseValue, T : Throwable>(private val executionThreads: ExecutionThreads) : UseCase<Q, R>() {
    protected val disposable: CompositeDisposable = CompositeDisposable()
    protected val defaultNext:(R) -> Unit = {}
    protected val defaultError:(T) -> Unit  = {Timber.e(it)}
    protected val defaultComplete:() -> Unit = {}

    @Suppress("UNCHECKED_CAST")
    open fun execute(requestValues: Q, next: (R) -> Unit = defaultNext, error: (T) -> Unit = defaultError, complete: () -> Unit = defaultComplete): Observable<R> {
        disposable.clear()
        val observable = execute(requestValues)
                .subscribeOn(executionThreads.io())
                .observeOn(executionThreads.ui())

        addDisposable(observable.subscribe(next, error as (Throwable) -> Unit, complete))
        return observable
    }

    fun dispose() {
        if (disposable.isDisposed) {
            disposable.dispose()
        }
    }

    /**
     * Dispose from current [CompositeDisposable].
     */
    private fun addDisposable(disposable: Disposable) {
        Preconditions.checkNotNull(disposable)
        Preconditions.checkNotNull(this.disposable)
        this.disposable.add(disposable)
    }
}
