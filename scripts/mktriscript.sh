#!/bin/bash

SRC_MONOPHONES=config/monophones
DST_TRIPHONES=logical_triphones

echo "CL ${DST_TRIPHONES}";
perl -ne 'chop; s/ //g; printf "TI \"T_%s\"{(\"%s\",\"*-%s+*\",\"%s+*\",\"*-%s\").transP}\n", $_,$_,$_,$_,$_ if ($_);' \
    $SRC_MONOPHONES;
