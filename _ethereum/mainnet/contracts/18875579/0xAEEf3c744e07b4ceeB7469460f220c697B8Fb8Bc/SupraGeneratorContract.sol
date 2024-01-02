// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BLS.sol";
import "./ReentrancyGuard.sol";
import "./Ownable2Step.sol";
import "./CheckContractAddress.sol";
import "./EnumerableSet.sol";
import "./ISupraRouterContract.sol";
import "./IDepositContract.sol";


/// @title VRF Generator Contract
/// @author Supra Developer
/// @notice This contract will generate random number based on the router contract request
/// @dev All function calls are currently implemented without side effects

abstract contract SupraGeneratorContract is
    ReentrancyGuard,
    Ownable2Step,
    CheckContractAddress
{
    /// @dev Public key
    uint256[4] public publicKey;

    /// @dev Domain
    bytes32 public domain;

    /// @dev Address of VRF Router contract
    address public supraRouterContract;

    address public depositContract;

    /// @dev BlockNumber
    uint256 internal blockNum = 0;

    /// @dev Instance Identification Number
    uint256 public instanceId;

    /// @dev Gas to be used for callback transaction fee
    uint256 public gasAfterPaymentCalculation;

    /// @dev Pre Compile Gas cost estimation value
    uint256 blsPreCompileGasCost;

    /// @dev A mapping that will keep track of all the nonces used, true means used and false means not used
    mapping(uint256 => bool) internal nonceUsed;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private whitelistedFreeNodes;

    /// @notice It will put the logs for the Generated request with necessary parameters
    /// @dev This event will be emitted when random number request generated
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param instanceId Instance Identification Number
    /// @param callerContract Contract address from which request has been generated
    /// @param functionName Function which we have to callback to fulfill request
    /// @param rngCount Number of random numbers requested
    /// @param numConfirmations Number of Confirmations
    /// @param clientSeed Client seed is used to add extra randomness
    /// @param clientWalletAddress is the wallet to which the request is associated
    event RequestGenerated(
        uint256 nonce,
        uint256 instanceId,
        address callerContract,
        string functionName,
        uint8 rngCount,
        uint256 numConfirmations,
        uint256 clientSeed,
        address clientWalletAddress
    );

    /// @notice To put log regarding updation of Public key
    /// @dev This event will be emmitted in whenever there is a request to update Public Key
    /// @param _timestamp epoch time when Public key has been updated
    event PublicKeyUpdated(uint256 _timestamp);

    /// @notice It will put log for the nonce value for which request has been fulfilled
    /// @dev It will be emitted when callback to the Router contract has been made
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param clientWalletAddress is the address through which the request is generated and the nonce is associated
    /// @param timestamp epoch time when a particular nonce was processed
    /// @param rngSuccess status for the callback transaction
    event NonceProcessed(
        uint256 nonce,
        address clientWalletAddress,
        uint256 timestamp,
        bool rngSuccess
    );

    /// @notice It will put log to the individual free node wallets those added to the whitelist
    /// @dev It will be emitted once the free node is added to the whitelist
    /// @param freeNodeWalletAddress is the address through which free node wallet is to be whitelisted
    event FreeNodeWhitelisted(address freeNodeWalletAddress);

    /// @notice It will put log to the multiple free node wallets those added to the whitelist in bulk
    /// @dev It will be emitted once multiple free nodes are added to the whitelist
    /// @param freeNodeWallets is the array of address through which is multiple free nodes are to be whitelisted
    event MultipleFreeNodesWhitelisted(address[] freeNodeWallets);

    /// @notice It will put log to the individual free node wallets those removed from the whitelist
    /// @dev It will be emitted once the free node is removed from the whitelist
    /// @param freeNodeWallet is the address which to be removed from the whitelist
    event FreeNodeRemovedFromWhitelist(address freeNodeWallet);

    constructor(
        bytes32 _domain,
        address _supraRouterContract,
        uint256[4] memory _publicKey,
        uint256 _instanceId,
        uint256 _blsPreCompileGasCost,
        uint256 _gasAfterPaymentCalculation
    ) {
        publicKey = _publicKey;
        domain = _domain;
        supraRouterContract = _supraRouterContract;
        instanceId = _instanceId;
        blsPreCompileGasCost = _blsPreCompileGasCost;
        gasAfterPaymentCalculation = _gasAfterPaymentCalculation;
    }

    /// @dev Set the gas required for callback transaction based on calculations
    /// @param _newGas The gas at the start of the transaction
    // Need to be setup in advance
    function setGasAfterPaymentCalculation(uint256 _newGas) external onlyOwner {
        gasAfterPaymentCalculation = _newGas;
    }

    /// @dev Generates a random number and initiates an RNG callback while handling payment processing.
    /// @param _nonce Nonce for the RNG request.
    /// @param _bhash Hash of the block where the request was made.
    /// @param _message Hash of the encoded data.
    /// @param _signature Signature of the message.
    /// @param _rngCount Number of random numbers to generate.
    /// @param _clientSeed Seed provided by the client.
    /// @param _callerContract Address of the calling contract.
    /// @param _func Name of the calling function.
    /// @param _clientWalletAddress Address of the client's wallet.
    /// @return _rngSuccess Indicates if the RNG callback was successful.
    /// @return paymentSuccess Indicates if the payment processing was successful.
    /// @return data Additional data returned from the RNG callback.
    function generateRngCallback(
        uint256 _nonce,
        bytes32 _bhash,
        bytes memory _message,
        uint256[2] calldata _signature,
        uint8 _rngCount,
        uint256 _clientSeed,
        address _callerContract,
        string calldata _func,
        address _clientWalletAddress
    )
        public
        nonReentrant
        returns (
            bool,
            bool,
            bytes memory
        )
    {
        uint256 startGas = gasleft();
        require(
            gasAfterPaymentCalculation != 0,
            "Generator_SC: Gas payment after calculation must be set!"
        );

        (bool _rngSuccess, bytes memory data) = _generateRngCallback(
            _nonce,
            _bhash,
            _message,
            _signature,
            _rngCount,
            _clientSeed,
            _callerContract,
            _func
        );
        uint256 _txnFee;
        _txnFee = calculatePaymentAmount(
                startGas,
                gasAfterPaymentCalculation
            );
        

        /** 
            :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                Method will call deposit contract and collect the fund from client's deposits to Supra fund.
            :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        */
        
        bytes memory encodedMethodWithParam = abi.encodeCall(
            IDepositContract.collectFund,
            (_clientWalletAddress,
            _txnFee)
        );

        (bool paymentSuccess, ) = address(depositContract).call(encodedMethodWithParam);
        require(paymentSuccess,"Payment Failed");
        emit NonceProcessed(_nonce, _clientWalletAddress, block.timestamp, _rngSuccess);

        return (_rngSuccess, paymentSuccess, data);
        
    }

    /// @dev Calculate the transaction fee for the callback transaction for Arbitrum
    /// @param _startGas The gas at the start of the transaction
    /// @param _gasAfterPaymentCalculation calculated gas value to be used based on iterative tests
    /// @return paymentWithoutFee The total estimated transaction fee for callback
    function calculatePaymentAmount(
        uint256 _startGas,
        uint256 _gasAfterPaymentCalculation
    ) internal virtual view returns (uint256) {}

    /// @dev Generates a random number internally.
    /// @param _nonce Nonce for the RNG request.
    /// @param _bhash Hash of the block where the request was made.
    /// @param _message Hash of the encoded data.
    /// @param _signature Signature of the message.
    /// @param _rngCount Number of random numbers to generate.
    /// @param _clientSeed Seed provided by the client.
    /// @param _callerContract Address of the calling contract.
    /// @param _func Name of the calling function.
    /// @return success Indicates if the processing was successful.
    /// @return data Additional data returned from the RNG callback.
    function _generateRngCallback(
        uint256 _nonce,
        bytes32 _bhash,
        bytes memory _message,
        uint256[2] calldata _signature,
        uint8 _rngCount,
        uint256 _clientSeed,
        address _callerContract,
        string calldata _func
    ) internal returns (bool, bytes memory) {
        require(
            isFreeNodeWhitelisted(msg.sender),
            "Free node is not whitelisted"
        );
        require(!nonceUsed[_nonce], "Nonce has already been processed");

        // Verify that the passed parameters do indeed hash to _message to ensure that the params
        // are not spoofed
        bytes memory encoded_data = abi.encode(
            _bhash,
            _nonce,
            _rngCount,
            instanceId,
            _callerContract,
            _func,
            _clientSeed
        );
        bytes32 keccak_encoded = keccak256(encoded_data);
        require(
            keccak_encoded == bytes32(_message),
            "Cannot verify the message"
        );
        // Verify the signature using the public key
        verify(_message, _signature);
        // Generate a random number
        // Use the signature as a seed and some transaction parameters, generate hash and convert to uint for random number
        uint256[] memory rngList = new uint256[](_rngCount);
        for (uint256 loop = 0; loop < _rngCount; ++loop) {
            rngList[loop] = uint256(
                keccak256(abi.encodePacked(_signature, loop + 1))
            );
        }
        (bool success, bytes memory data) = supraRouterContract.call(
            abi.encodeCall(
                ISupraRouterContract.rngCallback,
                (_nonce,
                rngList,
                _callerContract,
                _func)
            )
        );

        nonceUsed[_nonce] = true;
        return (success, data);
    }

    /// @notice This function is used to generate random number request
    /// @dev This function will be called from router contract which is for the random number generation request
    /// @param _nonce nonce is an incremental counter which is associated with request
    /// @param _callerContract Actual client contract address from which request has been generated
    /// @param _functionName A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @param _clientSeed Use of this is to add some extra randomness
    function rngRequest(
        uint256 _nonce,
        string memory _functionName,
        uint8 _rngCount,
        address _callerContract,
        uint256 _numConfirmations,
        uint256 _clientSeed,
        address _clientWalletAddress
    ) external {
        require(
            msg.sender == supraRouterContract,
            "Only router contract can execute this function"
        );
        emit RequestGenerated(
            _nonce,
            instanceId,
            _callerContract,
            _functionName,
            _rngCount,
            _numConfirmations,
            _clientSeed,
            _clientWalletAddress
        );
    }

    /// @notice The function will whitelist a single free node wallet
    /// @dev The function will whitelist a single free node at a time and will only be updated by the owner
    /// @param _freeNodeWallet this is the wallet address to be whitelisted
    function addFreeNodeToWhitelistSingle(address _freeNodeWallet)
        external
        onlyOwner
    {
        require(
            !isFreeNodeWhitelisted(_freeNodeWallet),
            "Free Node is already whitelisted"
        );
        whitelistedFreeNodes.add(_freeNodeWallet);
        emit FreeNodeWhitelisted(_freeNodeWallet);
    }

    /// @notice The function will whitelist multiple free node wallets
    /// @dev The function will whitelist multiple free node addresses passed altogether in an array
    /// @param _freeNodeWallets it is an array of address type, which accepts all the addresses to whitelist altogether
    function addFreeNodeToWhitelistBulk(address[] memory _freeNodeWallets)
        external
        onlyOwner
    {   
        address[] memory freeNodeWallets = new address[](_freeNodeWallets.length);
        for (uint256 loop = 0; loop < _freeNodeWallets.length; ++loop) {
            if(!isFreeNodeWhitelisted(_freeNodeWallets[loop])){
                whitelistedFreeNodes.add(_freeNodeWallets[loop]);
                freeNodeWallets[loop] = _freeNodeWallets[loop];
            }           
        }
        emit MultipleFreeNodesWhitelisted(freeNodeWallets);
    }

    /// @notice The function will remove the address from the whitelist
    /// @dev The function will remove the already whitelisted free node wallet
    /// @param _freeNodeWallet this is the wallet address that is to be removed from the list of whitelisted free node
    function removeFreeNodeFromWhitelist(address _freeNodeWallet)
        external
        onlyOwner
    {
        bool result = whitelistedFreeNodes.remove(_freeNodeWallet);
        require(result, "Free Node not whitelisted or already removed");
        emit FreeNodeRemovedFromWhitelist(_freeNodeWallet);
    }

    /// @notice The function will check if an address is whitelisted or not
    /// @dev The function will check if a particular free node is whitelisted or not and will return a boolean value accordingly
    /// @param _freeNodeWallet this is the wallet address to check if it is whitelisted or not
    function isFreeNodeWhitelisted(address _freeNodeWallet)
        public
        view
        returns (bool)
    {
        return whitelistedFreeNodes.contains(_freeNodeWallet);
    }

    /// @notice The function will return the list of whitelisted free nodes
    /// @dev The function will check for all the whitelisted free node wallets and return the list
    function listAllWhitelistedFreeNodes()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        address[] memory freenodes = new address[](
            whitelistedFreeNodes.length()
        );
        for (uint256 loop = 0; loop < whitelistedFreeNodes.length(); ++loop) {
            address value = whitelistedFreeNodes.at(loop);
            freenodes[loop] = value;
        }
        return freenodes;
    }

    /// @notice This function will be used to update public key
    /// @dev Update the public key state variable
    /// @param _publicKey New Public key which will update the old one
    /// @return bool It returns the status of updation of public key
    function updatePublicKey(uint256[4] memory _publicKey)
        external
        onlyOwner
        returns (bool)
    {
        publicKey = _publicKey;
        emit PublicKeyUpdated(block.timestamp);
        return true;
    }

    /// @notice This function is for updating the Deposit Contract Address
    /// @dev To update deposit contract address
    /// @param _newDepositSC contract address of the deposit/new deposit contract
    function updateDepositContract(address _newDepositSC) external onlyOwner {
        require(
            isContract(_newDepositSC),
            "Deposit contract address cannot be EOA"
        );
        require(
            _newDepositSC != address(0),
            "Deposit contract address cannot be a zero address"
        );
        depositContract = _newDepositSC;
    }

    function verify(bytes memory _message, uint256[2] calldata _signature)
        internal
        view
    {
        bool callSuccess;
        bool checkSuccess;
        (checkSuccess, callSuccess) = BLS.verifySingle(
            _signature,
            publicKey,
            BLS.hashToPoint(domain, _message),
            blsPreCompileGasCost
        );

        require(
            callSuccess,
            "Verify : Incorrect Public key or Signature Points"
        );
        require(checkSuccess, "Verify : Incorrect Input Message");
    }
}
