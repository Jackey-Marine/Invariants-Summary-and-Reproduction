276: 275-offline reproduce
280: 279-offline reproduce
432: 431-offline reproduce, StarSix with random disturbance(bad)
434: 431-offline reproduce, StarSix with random disturbance
436? 435-offline reproduce, ZigZag with random disturbance
465: 463-offline reproduce, acc_attack
466: 464-offline reproduce, acc_attack
486: 483-offline reproduce, acc_attack
488: 487-offline reproduce, acc_attack reference
495: 489-offline reproduce, gps & acc attack
506: 483-offline reproduce, acc_attack, only replace euler angles, start from 18s
507: 483-offline reproduce, acc_attack, only replace euler angles, start from 0s

========true sync=============
513: 483-offline reproduce, acc_attack, only replace euler angles, start from 0s, 
515: 483-offline reproduce, acc_attack, only replace euler angles, start from 12s, no crash check

518: 483-offline reproduce, acc_attack, only replace gyro angles, start from 12s, no crash check (wrong)
519: 483-offline reproduce, acc_attack, only replace gyro angles, start from 12s, no crash check
532: 528-offline reproduce, gyro gradual attack, add disturbance without sync
533: 528-offline reproduce, gyro gradual attack, replace attitude angles
534: 528-offline reproduce, gyro gradual attack, replace angular velocity

547: 542-offline reproduce, param tampering attack, PSC_VELXY_P scale 30, start 15s.
550: 548-offline reproduce, param tampering attack, PSC_VELXY_P scale 10, start when pitch change while turning.
551: 548-offline reproduce, param tampering attack, PSC_VELXY_P scale 10, start when pitch change while turning. (good, offset -0.1)
554: 552 reproduce
559: 557 reproduce (good)
562: 560 reproduce (good, offset 0.2)
564: 563 reproduce (good)

571: 567 reproduce
572: 568 reproduce
574: 569 reproduce
575: 570 reproduce
586: 577 reproduce

594: 592-reproduce, acc and gyro gradual attack together, replay with erle angle
595: 592-reproduce, acc and gyro gradual attack together, replay with gyro reading
596: 592-reproduce, acc and gyro gradual attack together, replay with disturbance