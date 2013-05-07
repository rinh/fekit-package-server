

# app -------------

rm -rf ../app/*

mkdir kkk
cp README.md kkk/README.md
cp app_0.0.1.config kkk/fekit.config
cd kkk
tar czf ../../app/datepicker-0.0.1.tgz fekit.config README.md
cd .. && rm -rf kkk


mkdir kkk
cp README.md kkk/README.md
cp app_0.0.2.config kkk/fekit.config
cd kkk
tar czf ../../app/datepicker-0.0.2.tgz fekit.config README.md
cd .. && rm -rf kkk




# end app ---------




# db -------------

rm -rf ../db/*

mkdir kkk && cd kkk
touch fekit.config
tar czf ../../db/datepicker.tgz fekit.config
cd .. && rm -rf kkk

# end db ---------



# read_package -------------

rm -rf ../read_package/*

# -- test1 

mkdir kkk
cp README.md kkk/README.md
cp test1.config kkk/fekit.config
cd kkk
tar czf ../../read_package/test1.tgz fekit.config README.md
cd .. && rm -rf kkk

# -- test2

mkdir kkk
cp README.md kkk/README.md
cp test2.config kkk/fekit.config
cd kkk
tar czf ../../read_package/test2.tgz fekit.config README.md
cd .. && rm -rf kkk


# -- test3

mkdir kkk
cp README.md kkk/README.md
cd kkk
tar czf ../../read_package/test3.tgz README.md
cd .. && rm -rf kkk

# -- test4

cp aaa.txt ../read_package/test4.tgz

# end read_package -------------