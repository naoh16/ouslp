#!/bin/sh
#
#
#
#    Copyright (C) 2013 Sunao HARA (hara@cs.okayama-u.ac.jp)
#    Copyright (C) 2013 Abe laboratory, Okayama university
#    Last Modified: 2013/11/19 14:17:27.
#

#DEST=model/mono01_0
#rm $DEST/hmmdefs
SRC=model/seed/proto_5states

for s in $( cat config/monophones ); do
	#sed -e "s/proto_5states/$s/g" < $SRC >> $DEST/hmmdefs
	sed -e "s/proto_5states/$s/g" < $SRC
done

#ls -al $DEST/hmmdefs
