library(metronautica)
local({
    fails <- function(z)inherits(tryCatch(force(z),error=identity),'error')
    fixture <- if(dir.exists('count-fixtures'))'count-fixtures' else file.path('tests','count-fixtures')
    expected <- read.csv(file.path(fixture,'published_reference.csv'))
    for(fs in unique(expected$fs)) {
        t <- (0:(fs*180-1))/fs
        frequency <- rep(c(0,.1,.5,1,2,5),each=fs*30)
        amplitude <- rep(c(0,.1,.3,.5,1,2),each=fs*30)
        x <- data.frame(time=as.POSIXct('2025-01-01',tz='UTC')+t,
            ax_g=amplitude*sin(2*pi*frequency*t),
            ay_g=.7*amplitude*cos(2*pi*frequency*t),
            az_g=1+.4*amplitude*sin(2*pi*frequency*t+.2))
        actual <- accel_metric_agcounts(x,1,fs)
        ref <- expected[expected$fs==fs,c('Axis1','Axis2','Axis3')]
        stopifnot(identical(unname(as.matrix(actual[,c('Axis1','Axis2','Axis3')])),
            unname(as.matrix(ref)*1)))
    }
    fs <- 100;t <- (0:5999)/fs
    x <- data.frame(time=as.POSIXct('2025-01-01',tz='UTC')+t,
        ax_g=sin(2*pi*t),ay_g=rep(0,6000),az_g=rep(1,6000))
    custom <- accel_metric_agcounts(x,1,fs,lower_hz=.69,upper_hz=10)
    ref <- read.csv(file.path(fixture,'custom_reference.csv'))
    stopifnot(all(as.matrix(custom[,names(ref)])==as.matrix(ref)))
    one <- accel_metric_agcounts(x,1,fs);five <- accel_metric_agcounts(list(data=x),5,fs)
    for(axis in c('Axis1','Axis2','Axis3'))stopifnot(all(five[[axis]]==colSums(matrix(one[[axis]],nrow=5))))
    stopifnot(all(five$value==round(sqrt(five$Axis1^2+five$Axis2^2+five$Axis3^2))))
    gapped <- x[-(2001:2100),]
    stopifnot(fails(accel_metric_agcounts(gapped,1,fs)))
    for(policy in c('zero','carry_forward')) {
        filled <- x
        if(policy=='zero')filled[2001:2100,c('ax_g','ay_g','az_g')] <- 0 else
            filled[2001:2100,c('ax_g','ay_g','az_g')] <- filled[rep(2000,100),c('ax_g','ay_g','az_g')]
        actual <- accel_metric_agcounts(gapped,1,fs,gap_policy=policy)
        ref <- accel_metric_agcounts(filled,1,fs)
        stopifnot(identical(actual$value,ref$value),sum(actual$missing_samples)==100,
            actual$imputed[21],actual$affected_by_imputation[22],
            attr(actual,'settings')$gap_policy==policy)
    }
    still <- x;still$ax_g <- 0;still$ay_g <- 0;still$az_g <- 0
    stopifnot(all(accel_metric_agcounts(still,1,fs)$value==0),
        sum(accel_metric_agcounts(still,1,fs)$missing_samples)==0)
    t0 <- min(x$time)
    stopifnot(fails(accel_metric_agcounts(x,1,fs,start_time=t0-2)),
        fails(accel_metric_agcounts(x,1,fs,start_time=t0-2,boundary='pad')))
    padded <- accel_metric_agcounts(x,1,fs,start_time=t0-2,boundary='pad',pad_value=c(0,0,0))
    stopifnot(nrow(padded)==62,sum(padded$padded_samples)==200,
        all(padded$imputed[1:2]),attr(padded,'settings')$padded_samples==200)
    partial <- accel_metric_agcounts(x[-6000,],5,fs)
    stopifnot(nrow(partial)==11,attr(partial,'settings')$discarded_trailing_samples==499)
    shifted <- x;shifted$time <- shifted$time+.03
    shifted_result <- accel_metric_agcounts(shifted,1,fs)
    stopifnot(as.numeric(shifted_result$time[1])==as.numeric(shifted$time[1]))
    for(args in list(list(lower_hz=.5),list(lower_hz=1,upper_hz=.5),
        list(lower_hz=.5,upper_hz=15),list(epoch_s=.5),list(fs_hz=125),list(filter_guard_s=-1))) {
        call <- list(tbl=x,epoch_s=1,fs_hz=fs);call[names(args)] <- args
        stopifnot(fails(do.call(accel_metric_agcounts,call)))
    }
    stopifnot(fails(compute_accel_summaries(x,measures='AG')),
        !grepl('agcounts',packageDescription('metronautica')$Suggests,fixed=TRUE))
    cat('Published/custom count fixtures, policies, flags, epoch boundaries and standalone-only integration passed.\n')
})
