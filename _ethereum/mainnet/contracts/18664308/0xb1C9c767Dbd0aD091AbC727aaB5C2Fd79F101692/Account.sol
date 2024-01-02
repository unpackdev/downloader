// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1271.sol";
import "./SignatureChecker.sol";

import "./IERC165.sol";
import "./IERC1155Receiver.sol";

import "./CrossChainExecutorList.sol";
import "./MinimalReceiver.sol";
import "./IAccount.sol";
import "./MinimalProxyStore.sol";
import "./console.sol";

/**
 * @title A smart contract wallet owned by a single ERC721 token
 * @author Jayden Windle (jaydenwindle)
 */

interface IRegistryContract {
    // function getMinimumLockup() external returns(uint256);
    function getCurrentCycle() external view returns (uint256);

    function getVgoldToken() external view returns (address);

    function getCycleNumToCycleEndTime(
        uint256 _cycleNum
    ) external view returns (uint256);
}

contract Account is IERC165, IERC1271, IAccount, MinimalReceiver {
    error NotAuthorized();
    error AccountLocked();
    error ExceedsMaxLockTime();

    CrossChainExecutorList public immutable crossChainExecutorList;

    /**
     * @dev Timestamp at which Account will unlock
     */
    uint256 public unlockTimestamp;

    /**
        to check if the contract is destroyed
        */
    bool public isDestroyed;

    /**
     * @dev Mapping from owner address to executor address
     */
    mapping(address => address) public executor;

    /**
     * @dev User Staking information
     */
    struct userStakeInfo {
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 cycleNum;
    }

    struct userStakeInfoWithArrayIndex {
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 arrayIndex;
    }


    /**
     * @dev User Staking information
     */
    mapping(uint256 => userStakeInfo[]) public userStake;

    /**
     * @dev User total staked VGOLD
     */
    uint256 public totalVgoldStake;

    mapping(uint256 => uint256) public totalVgoldStakeForCycle;

    // uint256 public

    /**
     * @dev User token deposit info
     */
    address[] public userDepositedTokenAddresses;

    /**
     * @dev Registry Contract Address
     */
    address public registryContract;

    mapping(uint256 => bool) public userstakedCycle;

    /**
     * @dev User NFT deposit info
     */
    address[] public userDepositedNFTAddresses;

    /**
     * @dev to check if the token was deposited or not
     */
    mapping(address => bool) public isthisTokenDeposited;

    /**
     * @dev to check if the NFT was deposited or not
     */
    mapping(address => bool) public isthisNFTDeposited;

    mapping(address => uint256[]) public NFTtokenIdDeposited;

    mapping(address => mapping(uint256 => bool)) NFTtokenIdexist;

    bool public isRegistrySet;

    /**
     * @dev Emitted whenever the lock status of a account is updated
     */
    event LockUpdated(uint256 timestamp);

    // Event emitted when an NFT is transferred
    event NFTTransferred(address from, address to, uint256 tokenId);

    // Event emitted when an ERC2O Token is transferred
    event ERC2OTokenTransferred(address from, address to, uint256 tokenId);

    uint256 public minLockup;

    // Event emitted when spender is approved
    event ERC20Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event ERC721Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    // Event emitted when ERC1155 tokens are transferred
    event BatchErc1155TokensTransferred(
        address from,
        address to,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    // Event emitted when an ERC1155 token is transferred
    event ERC1155TokenTransferred(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted whenever the executor for a account is updated
     */
    event ExecutorUpdated(address owner, address executor);

    /**
     * @dev Throws if called by any smart contract other than the registry.
     */
    modifier onlyRegistry() {
        _checkRegistry();
        _;
    }

    modifier onlyOnce() {
        require(!isRegistrySet, "Setter function can only be called once");
        _;
        isRegistrySet = true;
    }

    constructor(address _crossChainExecutorList) {
        crossChainExecutorList = CrossChainExecutorList(
            _crossChainExecutorList
        );
    }

    /**
     * @dev Ensures execution can only continue if the account is not locked
     */
    modifier onlyUnlocked() {
        if (unlockTimestamp > block.timestamp) revert AccountLocked();
        _;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        address _owner = owner();
        if (msg.sender != _owner) revert NotAuthorized();
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkRegistry() internal view virtual {
        require(registryContract == msg.sender, "Caller is not the Registry");
    }

    //UB
    /**
     * @dev gives deposited token Balalnce of this smart contract
     */
    function walletBalance(address tokenAddress) public view returns (uint256) {
        IERC20 erc20Contract = IERC20(tokenAddress);
        return erc20Contract.balanceOf(address(this));
    }

    // ----- WRITE Functions -------
    /**
     * @dev If account is unlocked and an executor is set, pass call to executor
     */
    fallback(
        bytes calldata data
    ) external payable onlyUnlocked returns (bytes memory result) {
        address _owner = owner();
        address _executor = executor[_owner];

        // accept funds if executor is undefined or cannot be called
        if (_executor.code.length == 0) return "";

        return _call(_executor, 0, data);
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an account owner.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyUnlocked returns (bytes memory result) {
        address _owner = owner();
        if (msg.sender != _owner) revert NotAuthorized();

        return _call(to, value, data);
    }

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAllERC1155(
        address tokenCollection,
        address operator,
        bool approved
    ) external onlyUnlocked onlyOwner {
        // Get the instance of the ERC1155 contract
        IERC1155 erc1155Contract = IERC1155(tokenCollection);

        // Check if the operator is nit owner
        require(
            operator == address(this),
            "NFTHandler: operator should not be owner"
        );
        // Transfer the tokens to the specified address
        erc1155Contract.setApprovalForAll(operator, approved);

        // Emit the ApprovalForAll event
        emit ApprovalForAll(address(this), operator, approved);
    }

    // Transfer ERC1155 tokens from this contract to another address
    function batchTransferERC1155Tokens(
        address tokenCollection,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyUnlocked onlyOwner {
        require(
            tokenIds.length == amounts.length,
            "ERC1155Handler: Invalid input length"
        );

        // Get the instance of the ERC1155 contract
        IERC1155 erc1155Contract = IERC1155(tokenCollection);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                erc1155Contract.balanceOf(address(this), tokenIds[i]) >=
                    amounts[i],
                "ERC1155Handler: Insufficient balance"
            );
        }

        // Batch transfer the tokens to the specified address
        erc1155Contract.safeBatchTransferFrom(
            address(this),
            to,
            tokenIds,
            amounts,
            ""
        );

        // Emit the TokensTransferred event
        emit BatchErc1155TokensTransferred(
            address(this),
            to,
            tokenIds,
            amounts
        );
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an authorized executor.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeTrustedCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyUnlocked returns (bytes memory result) {
        address _executor = executor[owner()];
        if (msg.sender != _executor) revert NotAuthorized();

        return _call(to, value, data);
    }

    // TODO - remove if not needed

    /**
     * @dev Executes a transaction from the Account. Must be called by a trusted cross-chain executor.
     * Can only be called if account is owned by a token on another chain.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeCrossChainCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyUnlocked returns (bytes memory result) {
        (uint256 chainId, , ) = context();

        if (chainId == block.chainid) {
            revert NotAuthorized();
        }

        if (!crossChainExecutorList.isCrossChainExecutor(chainId, msg.sender)) {
            revert NotAuthorized();
        }

        return _call(to, value, data);
    }

    /**
     * @dev Sets executor address for Account, allowing owner to use a custom implementation if they choose to.
     * When the token controlling the account is transferred, the implementation address will reset
     *
     * @param _executionModule the address of the execution module
     */
    function setExecutor(address _executionModule) external onlyUnlocked {
        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        executor[_owner] = _executionModule;

        emit ExecutorUpdated(_owner, _executionModule);
    }

    // TODO : in review
    /**
     * @dev Locks Account, preventing transactions from being executed until a certain time
     * Note: Lock time should not be greater than 1 year here.
     *
     * @param _unlockTimestamp timestamp when the account will become unlocked
     */
    function lock(uint256 _unlockTimestamp) external onlyUnlocked {
        if (_unlockTimestamp > block.timestamp + 365 days)
            revert ExceedsMaxLockTime();

        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        unlockTimestamp = _unlockTimestamp;

        emit LockUpdated(_unlockTimestamp);
    }

    /**
     * @dev Returns Account lock status
     *
     * @return true if Account is locked, false otherwise
     */
    function isLocked() external view returns (bool) {
        return unlockTimestamp > block.timestamp;
    }

    /**
     * @dev Returns true if caller is authorized to execute actions on this account
     *
     * @param caller the address to query authorization for
     * @return true if caller is authorized, false otherwise
     */
    function isAuthorized(address caller) external view returns (bool) {
        (uint256 chainId, address tokenCollection, uint256 tokenId) = context();

        if (chainId != block.chainid) {
            return crossChainExecutorList.isCrossChainExecutor(chainId, caller);
        }

        address _owner = IERC721(tokenCollection).ownerOf(tokenId);
        if (caller == _owner) return true;

        address _executor = executor[_owner];
        if (caller == _executor) return true;

        return false;
    }

    // TODO : remove me if not needed

    /**
     * @dev Implements EIP-1271 signature validation
     *
     * @param hash      Hash of the signed data
     * @param signature Signature to validate
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        // If account is locked, disable signing
        if (unlockTimestamp > block.timestamp) return "";

        // If account has an executor, check if executor signature is valid
        address _owner = owner();
        address _executor = executor[_owner];

        if (
            _executor != address(0) &&
            SignatureChecker.isValidSignatureNow(_executor, hash, signature)
        ) {
            return IERC1271.isValidSignature.selector;
        }

        // Default - check if signature is valid for account owner
        if (SignatureChecker.isValidSignatureNow(_owner, hash, signature)) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /**
     * @dev Implements EIP-165 standard interface detection
     *
     * @param interfaceId the interfaceId to check support for
     * @return true if the interface is supported, false otherwise
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC1155Receiver) returns (bool) {
        // default interface support
        if (
            interfaceId == type(IAccount).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId
        ) {
            return true;
        }

        address _executor = executor[owner()];

        if (_executor == address(0) || _executor.code.length == 0) {
            return false;
        }

        // if interface is not supported by default, check executor
        try IERC165(_executor).supportsInterface(interfaceId) returns (
            bool _supportsInterface
        ) {
            return _supportsInterface;
        } catch {
            return false;
        }
    }

    /**
     * @dev Returns the owner of the token that controls this Account (public for Ownable compatibility)
     *
     * @return the address of the Account owner
     */
    function owner() public view returns (address) {
        (uint256 chainId, address tokenCollection, uint256 tokenId) = context();

        if (chainId != block.chainid) {
            return address(0);
        }

        return IERC721(tokenCollection).ownerOf(tokenId);
    }

    /**
     * @dev Returns information about the token that owns this account
     *
     * @return tokenCollection the contract address of the  ERC721 token which owns this account
     * @return tokenId the tokenId of the  ERC721 token which owns this account
     */
    function token()
        public
        view
        returns (address tokenCollection, uint256 tokenId)
    {
        (, tokenCollection, tokenId) = context();
    }

    function context() internal view returns (uint256, address, uint256) {
        bytes memory rawContext = MinimalProxyStore.getContext(address(this));
        if (rawContext.length == 0) return (0, address(0), 0);

        return abi.decode(rawContext, (uint256, address, uint256));
    }

    /**
     * @dev Executes a low-level call
     */
    function _call(
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function setMinLockup(uint256 _time) public onlyRegistry {
        minLockup = _time;
    }

    function setRegistry(address _registry) public onlyOnce {
        registryContract = _registry;
    }

    function getCycleEndTime(uint256 _cycleNum) public view returns (uint256) {
        return
            IRegistryContract(registryContract).getCycleNumToCycleEndTime(
                _cycleNum
            );
    }

    function getUserStakedCycles() public view returns(uint256[] memory){
        uint256 currentCycle = IRegistryContract(registryContract).getCurrentCycle();
        uint256[] memory userStakedCycles = new uint256[](currentCycle);
        uint256 arrayCount;
        for(uint i=1 ; i <= currentCycle; i++){
            if(userstakedCycle[i]){
                userStakedCycles[arrayCount] = i;
                arrayCount++;
            }
        }
        return userStakedCycles;
    }

    function getTotalVgoldStakeForCycle(
        uint256 _cycleNum
    ) public view returns (uint256) {
        return totalVgoldStakeForCycle[_cycleNum];
    }

    //UB
    function stake(
        uint256 _amount,
        uint256 _cycleNum
    ) external onlyUnlocked onlyRegistry {
        userStakeInfo memory stakeInfo = userStakeInfo(
            _amount,
            block.timestamp,
            _cycleNum
        );
        userStake[_cycleNum].push(stakeInfo);
        totalVgoldStake += _amount;
        totalVgoldStakeForCycle[_cycleNum] += _amount;
        userstakedCycle[_cycleNum] = true;
    }

    //UB
    function postClaim(
        uint256 _timeStamp,
        uint256 _cycleNum
    ) external onlyRegistry onlyUnlocked {
        for (uint i = 0; i < userStake[_cycleNum].length; i++) {
            if (
                userStake[_cycleNum][i].stakeTime + minLockup <= block.timestamp
            ) {
                userStake[_cycleNum][i].stakeTime = _timeStamp;
            }
        }
    }

    //UB
    function calculateEligibleStake(
        uint256 _cycleNum
    ) public view returns (uint256) {
        uint256 eligibleStake;
        for (uint i = 0; i < userStake[_cycleNum].length; i++) {
            if (
                userStake[_cycleNum][i].stakeTime + minLockup <= block.timestamp
            ) {
                eligibleStake += userStake[_cycleNum][i].stakeAmount;
            }
        }
        return eligibleStake;
    }

    function calculateEligibleStakeArray(
        uint256[] memory _arrayIndexes,
        uint256 _cycleNum
    ) public view returns (uint256) {
        uint256 eligibleStake;
        for (uint i; i < _arrayIndexes.length; i++) {
            require(
                _arrayIndexes[i] <= userStake[_cycleNum].length,
                "ArrayIndex beyond array length"
            );
            if (
                userStake[_cycleNum][_arrayIndexes[i]].stakeTime + minLockup <=
                block.timestamp
            ) {
                eligibleStake += userStake[_cycleNum][_arrayIndexes[i]]
                    .stakeAmount;
            }
        }
        return eligibleStake;
    }

    function postUnstakeForArray(
        uint256[] memory _arrayIndexes,
        uint256 _cycleNum
    ) public onlyRegistry returns (uint256) {
        address VGOLDtoken = IRegistryContract(registryContract)
            .getVgoldToken();
        uint256 totalUnstake;
        for (uint i; i < _arrayIndexes.length; i++) {
            require(
                _arrayIndexes[i] <= userStake[_cycleNum].length,
                "ArrayIndex beyond array length"
            );
            IERC20(VGOLDtoken).transfer(
                owner(),
                userStake[_cycleNum][_arrayIndexes[i]].stakeAmount
            );
            totalUnstake += userStake[_cycleNum][_arrayIndexes[i]].stakeAmount;

            userStake[_cycleNum][_arrayIndexes[i]].stakeAmount = 0;
            userStake[_cycleNum][_arrayIndexes[i]].stakeTime = 0;
        }
        totalVgoldStake -= totalUnstake;
        totalVgoldStakeForCycle[_cycleNum] -= totalUnstake;
        return totalUnstake;
    }

    function postUnstakeForCycle(
        uint256 _cycleNum
    ) external onlyRegistry onlyUnlocked returns (bool) {
        address VGOLDtoken = IRegistryContract(registryContract)
            .getVgoldToken();
        IERC20(VGOLDtoken).transfer(
            owner(),
            totalVgoldStakeForCycle[_cycleNum]
        );
        for (uint i; i < userStake[_cycleNum].length; i++) {
            userStake[_cycleNum][i].stakeAmount = 0;
            userStake[_cycleNum][i].stakeTime = 0;
        }
        totalVgoldStake -= totalVgoldStakeForCycle[_cycleNum];
        totalVgoldStakeForCycle[_cycleNum] = 0;
        userstakedCycle[_cycleNum] = false;
        return true;
    }

    //UB
    /**
     * @dev deposit any ERC 20 token in the NFT wallet account
     * Note: this funciton will have unique ids for a particular NFT to execute
     */
    function depositToken(
        address tokenAddress,
        uint amount
    ) external onlyUnlocked onlyOwner {
        // Get the instance of the IERC20 contract
        IERC20 erc20Contract = IERC20(tokenAddress);
        // Check if amount > 0
        require(amount > 0, "Amount should be greater than 0");
        //Token transfer to the wallet account
        require(
            erc20Contract.transferFrom(msg.sender, address(this), amount),
            "Token deposit failed"
        );
        //Saving new deposit token addresses
        if (!isthisTokenDeposited[tokenAddress]) {
            userDepositedTokenAddresses.push(tokenAddress);
            isthisTokenDeposited[tokenAddress] = true;
        }
        emit ERC2OTokenTransferred(msg.sender, address(this), amount);
    }

    //UB
    /**
     * @dev function allows user to deposit NFT
     */
    function depositNFT(
        address tokenAddress,
        uint256 tokenId
    ) external onlyUnlocked onlyOwner {
        // Get the instance of the ERC721 contract
        IERC721 nftContract = IERC721(tokenAddress);
        // Check if the sender is the current owner of the NFT
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "NFTHandler: Sender is not the owner"
        );
        // Transfer the NFT to the specified address
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);

        //Saving new deposit token addresses
        if (!isthisNFTDeposited[tokenAddress]) {
            userDepositedNFTAddresses.push(tokenAddress);
            isthisNFTDeposited[tokenAddress] = true;
        }
        NFTtokenIdDeposited[tokenAddress].push(tokenId);
        NFTtokenIdexist[tokenAddress][tokenId] = true;
        // Emit the NFTTransferred event
        emit NFTTransferred(msg.sender, address(this), tokenId);
    }

    //UB
    /**
     * @dev This function allow the wallet owner to withdraw the deposited token
     */
    function withdrawToken(
        address tokenAddress,
        uint amount
    ) external onlyUnlocked onlyOwner {
        // Get the instance of the IERC20 contract
        IERC20 erc20Contract = IERC20(tokenAddress);
        // Check if amount > 0
        require(amount > 0, "Amount should be greater than 0");
        // Check if contarct has enough balance
        require(
            erc20Contract.balanceOf(address(this)) >= amount,
            "not enough token balance for withdrawl"
        );
        require(
            erc20Contract.transfer(msg.sender, amount),
            "token withdrawl failed"
        );
        emit ERC2OTokenTransferred(address(this), msg.sender, amount);
    }

    //UB
    /**
     * @dev This function allow the wallet owner to withdraw the deposited NFT
     */
    function withdrawNFT(
        address tokenAddress,
        uint256 tokenId
    ) public onlyUnlocked onlyOwner {
        // Get the instance of the ERC721 contract
        IERC721 nftContract = IERC721(tokenAddress);

        // Check if the sender is the current owner of the NFT
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "NFTHandler: Contract doesn't owns this NFT"
        );

        // Transfer the NFT to the specified address
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

        NFTtokenIdexist[tokenAddress][tokenId] = false;

        // Emit the NFTTransferred event
        emit NFTTransferred(address(this), msg.sender, tokenId);
    }

    function getTokenIdsDepositedOfNFT(address _nftAddress) public view returns(uint256[] memory){
        uint256 length = NFTtokenIdDeposited[_nftAddress].length;
        uint256[] memory tokenIds = new uint256[](length);
        uint256 arrayCount;
        for(uint256 i; i < length; i++){
            uint256 tokenId = NFTtokenIdDeposited[_nftAddress][i];
            if(NFTtokenIdexist[_nftAddress][tokenId]){
                tokenIds[arrayCount] = tokenId;
                arrayCount++;
            }
        }
        return tokenIds;
    }

    //UB
    function getStakesForCyCle(
        uint _cycleNum
    )
        public
        view
        returns (
            userStakeInfoWithArrayIndex[] memory,
            userStakeInfoWithArrayIndex[] memory
        )
    {
        userStakeInfoWithArrayIndex[]
            memory eligibleStakes = new userStakeInfoWithArrayIndex[](
                userStake[_cycleNum].length
            );
        userStakeInfoWithArrayIndex[]
            memory nonEligibleStakes = new userStakeInfoWithArrayIndex[](
                userStake[_cycleNum].length
            );
        uint256 eligibleCount;
        uint256 nonEligibleCount;
        for (uint i = 0; i < userStake[_cycleNum].length; i++) {
            console.log(
                userStake[_cycleNum][i].stakeTime + minLockup > block.timestamp,
                "if condition"
            );
            if (
                userStake[_cycleNum][i].stakeAmount == 0 &&
                userStake[_cycleNum][i].stakeTime == 0
            ) {
                continue;
            } else if (
                userStake[_cycleNum][i].stakeTime + minLockup > block.timestamp
            ) {
                nonEligibleStakes[nonEligibleCount].stakeTime = userStake[
                    _cycleNum
                ][i].stakeTime;
                nonEligibleStakes[nonEligibleCount].stakeAmount = userStake[
                    _cycleNum
                ][i].stakeAmount;
                nonEligibleStakes[nonEligibleCount].arrayIndex = i;
                nonEligibleCount++;
            } else {
                eligibleStakes[eligibleCount].stakeTime = userStake[_cycleNum][
                    i
                ].stakeTime;
                eligibleStakes[eligibleCount].stakeAmount = userStake[
                    _cycleNum
                ][i].stakeAmount;
                eligibleStakes[eligibleCount].arrayIndex = i;
                eligibleCount++;
            }
        }
        return (eligibleStakes, nonEligibleStakes);
    }

    //UB
    /**
     * @dev This function allow the wallet owner to destroy the contract and get all the funds
     */
    function destroy() public onlyOwner {
        require(!isDestroyed, "The contract has already been destroyed");

        address payable payableOwner = payable(msg.sender);

        // Perform any cleanup or asset transfers here
        //Transfer ethers
        uint256 contractBalanceEther = address(this).balance;
        if (contractBalanceEther > 0) {
            payable(msg.sender).transfer(contractBalanceEther);
        }

        //Transfer other tokens
        for (uint i = 0; i < userDepositedTokenAddresses.length; i++) {
            address tokenAddress = userDepositedTokenAddresses[i];
            // Get the instance of the IERC20 contract
            IERC20 erc20Contract = IERC20(tokenAddress);
            uint256 contractBalanceToken = erc20Contract.balanceOf(
                address(this)
            );
            if (contractBalanceToken > 0) {
                erc20Contract.transfer(msg.sender, contractBalanceToken);
            }
        }

        //Transfer NFTs
        for (uint i = 0; i < userDepositedNFTAddresses.length; i++) {
            address NFTAddress = userDepositedNFTAddresses[i];
            for (uint j = 0; j < NFTtokenIdDeposited[NFTAddress].length; j++) {
                uint256 tokenId = NFTtokenIdDeposited[NFTAddress][j];
                if(NFTtokenIdexist[NFTAddress][j]){
                    withdrawNFT(NFTAddress, tokenId);
                }
            }
        }
        //Transfer rest of the funds
        selfdestruct(payableOwner);

        // Mark the contract as destroyed
        isDestroyed = true;
    }
}
