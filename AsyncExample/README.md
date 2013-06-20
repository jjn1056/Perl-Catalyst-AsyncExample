Update deps first, then

    cpanm -installdeps .
    cpanm Catalyst
    

Run `plackup -Ilib asyncexample-ioasync.psgi`. To test the application access (http://0.0.0.0:5000/anyevent/chat)[http://0.0.0.0:5000/anyevent/chat] 

