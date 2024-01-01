pragma solidity 0.8.23;

// H   H  OOO  N   N K   K TTTTT  OOO  OOO  L     SSS
// H   H O   O NN  N K  K    T   O   O O   O L    S
// HHHHH O   O N N N KKK     T   O   O O   O L     SSS
// H   H O   O N  NN K  K    T   O   O O   O L        S
// H   H  OOO  N   N K   K   T    OOO   OOO  LLLL SSS

/**
 * @title HonkToolsV1 by the Hyppocritez
 * @dev This contract allows users to create permanent inscriptions (ethscriptions) on the blockchain.
 *      Ethscriptions once made are immutable and stored eternally on-chain.
 *      The protocol is designed to be extendable and compatible with various use cases,
 *      including but not limited to, digital art, messages, and public information.
 *      Hyppocritez team reserves all rights to administer this smart contract as seen fit
 *      In case of error or critical issue we reserve the right to modify the smart contract state as needed
 */
 
contract HonkToolsV1 {
    bool public initialized;
    bool public paused;
    bool public forwardAllFunds;
    address public fundReceiver;
    address public owner;
    address public controller;
    mapping(bytes32 => bool) public uniqueHash;
    mapping(string => bool) public uniqueSalt;

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    event ethscriptions_protocol_TransferEthscription(address indexed recipient, bytes32 indexed ethscriptionId);

    event ProductPurchasedWithSignature(address purchaser, string productId, bytes32 sha256Hash, uint256 expiry);

    event UserEthWithdrawn(address user, uint256 amount, string salt, uint256 expiry);

    event ChangeOwner(address newOwner);

    event ChangeController(address newController);

    event ChangeFundReceiver(address newReceiver);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    constructor(){
    }

    function initialize() public{
        if(!initialized){
            forwardAllFunds = false;
            fundReceiver = address(0);
            owner = msg.sender;
            controller = msg.sender;
            paused = false;
            initialized = true;
        }
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit ChangeOwner(owner);
    }

    function changeController(address newController) public onlyOwner {
        controller = newController;
        emit ChangeController(controller);
    }
    function changeFundReceiver(address newFundReceiver) public onlyOwner {
        fundReceiver = newFundReceiver;
        if(newFundReceiver == address(0)){
            forwardAllFunds = false;
        } else {
            forwardAllFunds = true;
        }
        emit ChangeFundReceiver(newFundReceiver);
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function inscribeWithSignature(string memory inscriptionData,  string memory salt, bytes memory signature, uint256 expiry) public notPaused payable {
        require(expiry == 0 || expiry >= _getNow(), "Expired");

        require(!uniqueSalt[salt], "Salt has already been used");

        require(uniqueHash[sha256(abi.encodePacked(inscriptionData))] == false, "Not Unique Hash");

        bytes32 dataHash = keccak256(abi.encodePacked(inscriptionData, msg.sender, salt, expiry));

        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)); // check if useful later
        address recovered = getRecoveredAddress(signature, prefixedHash);

        require(recovered == controller, "Signature Message is invalid");

        uniqueSalt[salt] = true;

        if(forwardAllFunds){
            (bool success, ) = fundReceiver.call{value: msg.value}("");
            require(success, "Transfer failed");
        }

        emit ethscriptions_protocol_CreateEthscription(msg.sender, string(abi.encodePacked(inscriptionData)));
    }

    function inscribePurchaseWithSignature(string memory inscriptionData,  string memory salt, bytes memory signature, uint256 expiry, string memory productId, bool unique) public notPaused payable {
        require(expiry == 0 || expiry >= _getNow(), "Expired");
        require(!uniqueSalt[salt], "Salt has already been used");

        require(!unique || (unique && uniqueHash[sha256(abi.encodePacked(inscriptionData))]) == false, "Not Unique Hash");

        bytes32 dataHash = keccak256(abi.encodePacked(inscriptionData, msg.sender, salt, expiry, productId, unique));

        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)); // check if useful later
        address recovered = getRecoveredAddress(signature, prefixedHash);

        require(recovered == controller, "Signature Message is invalid");

        uniqueSalt[salt] = true;

        if(forwardAllFunds){
            (bool success, ) = fundReceiver.call{value: msg.value}("");
            require(success, "Transfer failed");
        }

        emit ethscriptions_protocol_CreateEthscription(msg.sender, string(abi.encodePacked(inscriptionData)));
        uniqueHash[sha256(abi.encodePacked(inscriptionData))] = true;
        emit ProductPurchasedWithSignature(msg.sender, productId, sha256(abi.encodePacked(inscriptionData)), expiry);
    }

    function withdrawOwnerETH(uint256 amount) public onlyOwner {
        owner.call{value: amount}("");
    }

    function withdrawUserEthscriptions(bytes memory ethscriptionsIdsData, string memory salt, bytes memory signature, uint256 expiry) public notPaused {
        require(expiry == 0 || expiry >= _getNow(), "Expired");
        require(!uniqueSalt[salt], "Salt has already been used");

        bytes32[] memory ethscriptionsIds = abi.decode(ethscriptionsIdsData, (bytes32[]));
        require(ethscriptionsIds.length > 0, "There must be 1 or more tokens being sent");

        bytes32 dataHash = keccak256(abi.encodePacked(ethscriptionsIdsData, msg.sender, salt, expiry));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)); // check if useful later
        address recovered = getRecoveredAddress(signature, prefixedHash);


        require(recovered == controller, "Signature Message is invalid");

        uniqueSalt[salt] = true;

        for(uint256 i= 0; i < ethscriptionsIds.length; i++){
            emit ethscriptions_protocol_TransferEthscription(msg.sender, ethscriptionsIds[i]);
        }
    }

    function withdrawUserEth(uint256 amount, string memory salt, bytes memory signature, uint256 expiry) public notPaused {
        require(expiry == 0 || expiry >= _getNow(), "Expired");
        require(!uniqueSalt[salt], "Salt has already been used");

        require(amount > 0, "Must send more than 0 eth");

        bytes32 dataHash = keccak256(abi.encodePacked(amount, msg.sender, salt, expiry));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)); // check if useful later
        address recovered = getRecoveredAddress(signature, prefixedHash);

        require(recovered == controller, "Signature Message is invalid");

        uniqueSalt[salt] = true;

        emit UserEthWithdrawn(msg.sender, amount, salt,expiry);

        address payable ethRecipient = payable(msg.sender);
        ethRecipient.transfer(amount);
    }

    function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
    public
    pure
    returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    receive() external payable {
    }

    fallback() external {
    }
}