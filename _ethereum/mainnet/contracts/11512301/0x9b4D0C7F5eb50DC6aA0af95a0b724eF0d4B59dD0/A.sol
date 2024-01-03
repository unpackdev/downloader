contract A {
    constructor( address payable pavel) payable{
        // Pavel Fedortsov, I dont like frontrunners
        pavel.transfer(msg.value);
    }
}