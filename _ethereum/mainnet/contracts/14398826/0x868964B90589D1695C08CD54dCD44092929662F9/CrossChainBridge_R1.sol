// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ICrossChainBridge.sol";
import "./IERC20.sol";
import "./EthereumVerifier.sol";
import "./ProofParser.sol";
import "./Utils.sol";
import "./SimpleToken.sol";
import "./InternetBond.sol";
import "./InternetBondRatioFeed.sol";
import "./BridgeRouter.sol";

contract CrossChainBridge_R1 is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ICrossChainBridge {

    mapping(uint256 => address) private _bridgeAddressByChainId;
    address private _consensusAddress;
    mapping(bytes32 => bool) private _usedProofs;
    address private _tokenImplementation;
    mapping(address => address) private _peggedTokenOrigin;
    Metadata _nativeTokenMetadata;
    address private _bondImplementation;
    IInternetBondRatioFeed private _internetBondRatioFeed;
    BridgeRouter private _bridgeRouter;

    function initialize(
        address consensusAddress,
        SimpleTokenFactory tokenFactory,
        InternetBondFactory bondFactory,
        string memory nativeTokenSymbol,
        string memory nativeTokenName,
        InternetBondRatioFeed bondFeed,
        BridgeRouter router
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __CrossChainBridge_init(consensusAddress, tokenFactory, bondFactory, nativeTokenSymbol, nativeTokenName, bondFeed, router);
    }

    function getTokenImplementation() public view override returns (address) {
        return _tokenImplementation;
    }

    function setTokenFactory(SimpleTokenFactory factory) public onlyOwner {
        _tokenImplementation = factory.getImplementation();
        require(_tokenImplementation != address(0x0));
        emit TokenImplementationChanged(_tokenImplementation);
    }

    function getBondImplementation() public view override returns (address) {
        return _bondImplementation;
    }

    function setBondFactory(InternetBondFactory factory) public onlyOwner {
        _bondImplementation = factory.getImplementation();
        require(_bondImplementation != address(0x0));
        emit BondImplementationChanged(_tokenImplementation);
    }

    function getNativeAddress() public view returns (address) {
        return _nativeTokenMetadata.originAddress;
    }

    function getOrigin(address token) internal view returns (uint256, address) {
        if (token == _nativeTokenMetadata.originAddress) {
            return (0, address(0x0));
        }
        try IERC20Pegged(token).getOrigin() returns (uint256 chain, address origin) {
            return (chain, origin);
        } catch {}
        return (0, address(0x0));
    }

    function __CrossChainBridge_init(
        address consensusAddress,
        SimpleTokenFactory tokenFactory,
        InternetBondFactory bondFactory,
        string memory nativeTokenSymbol,
        string memory nativeTokenName,
        InternetBondRatioFeed bondFeed,
        BridgeRouter router
    ) internal {
        _consensusAddress = consensusAddress;
        _tokenImplementation = tokenFactory.getImplementation();
        _bondImplementation = bondFactory.getImplementation();
        _nativeTokenMetadata = Metadata(
            Utils.stringToBytes32(nativeTokenSymbol),
            Utils.stringToBytes32(nativeTokenName),
            Utils.currentChain(),
            // generate unique address that will not collide with any contract address
            address(bytes20(keccak256(abi.encodePacked("CrossChainBridge:", nativeTokenSymbol)))),
            0x0
        );
        _internetBondRatioFeed = bondFeed;
        _bridgeRouter = router;
    }

    // HELPER FUNCTIONS

    function isPeggedToken(address toToken) public view override returns (bool) {
        return _peggedTokenOrigin[toToken] != address(0x00);
    }

    function getRatio(address token) public view returns (uint256) {
        return _internetBondRatioFeed.getRatioFor(token);
    }

    function getBondType(address token) public view returns (InternetBondType) {
        try IERC20InternetBond(token).isRebasing() returns (bool isRebasing) {
            if (isRebasing) return InternetBondType.REBASING_BOND;
            else return InternetBondType.NONREBASING_BOND;
        } catch {
        }
        return InternetBondType.NOT_BOND;
    }

    function getNativeRatio(address token) public view returns (uint256) {
        try IERC20InternetBond(token).ratio() returns (uint256 ratio) {
            return ratio;
        } catch {
        }
        return 0;
    }

    function createBondMetadata(uint8 version, InternetBondType bondType) internal pure returns (bytes32) {
        bytes32 result = 0x0;
        result |= bytes32(bytes1(version));
        result |= bytes32(bytes1(uint8(bondType))) >> 8;
        return result;
    }

    // DEPOSIT FUNCTIONS

    function deposit(uint256 toChain, address toAddress) public payable nonReentrant whenNotPaused override {
        _depositNative(toChain, toAddress, msg.value);
    }

    function deposit(address fromToken, uint256 toChain, address toAddress, uint256 amount) public nonReentrant whenNotPaused override {
        (uint256 chain, address origin) = getOrigin(fromToken);
        if (chain != 0) {
            /* if we have pegged contract then its pegged token */
            _depositPegged(fromToken, toChain, toAddress, amount, chain, origin);
        } else {
            /* otherwise its erc20 token, since we can't detect is it erc20 token it can only return insufficient balance in case of any errors */
            _depositErc20(fromToken, toChain, toAddress, amount);
        }
    }

    function _depositNative(uint256 toChain, address toAddress, uint256 totalAmount) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        /* we need to calculate peg token contract address with meta data */
        address toToken = _bridgeRouter.peggedTokenAddress(address(toBridge), _nativeTokenMetadata.originAddress);
        /* emit event with all these params */
        emit DepositLocked(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            _nativeTokenMetadata.originAddress, // this is our current native token (e.g. ETH, MATIC, BNB, etc)
            toToken, // this is an address of our target pegged token
            totalAmount, // how much funds was locked in this contract
            _nativeTokenMetadata // meta information about
        );
    }

    function _depositPegged(address fromToken, uint256 toChain, address toAddress, uint256 totalAmount, uint256 chain, address origin) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        /* check allowance and transfer tokens */
        require(IERC20Upgradeable(fromToken).balanceOf(fromAddress) >= totalAmount, "insufficient balance");
        InternetBondType bondType = getBondType(fromToken);
        uint256 amt;
        if (bondType == InternetBondType.REBASING_BOND) {
            amt = _peggedAmountToShares(totalAmount, getRatio(origin));
        } else {
            amt = totalAmount;
        }
        address toToken;
        if (bondType == InternetBondType.NOT_BOND) {
            toToken = _peggedDestinationErc20Token(fromToken, origin, toChain, chain);
        } else {
            toToken = _peggedDestinationErc20Bond(fromToken, origin, toChain, chain);
        }
        IERC20Mintable(fromToken).burn(fromAddress, amt);
        Metadata memory metaData = Metadata(
            Utils.stringToBytes32(IERC20Extra(fromToken).symbol()),
            Utils.stringToBytes32(IERC20Extra(fromToken).name()),
            chain,
            origin,
            createBondMetadata(0, bondType)
        );
        /* emit event with all these params */
        emit DepositBurned(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            fromToken, // this is our current native token (can be ETH, CLV, DOT, BNB or something else)
            toToken, // this is an address of our target pegged token
            amt, // how much funds was locked in this contract
            metaData,
            origin
        );
    }

    function _peggedAmountToShares(uint256 amount, uint256 ratio) internal pure returns (uint256) {
        require(ratio > 0, "zero ratio");
        return Utils.multiplyAndDivideFloor(amount, ratio, 1e18);
    }

    function _nativeAmountToShares(uint256 amount, uint256 ratio, uint8 decimals) internal pure returns (uint256) {
        require(ratio > 0, "zero ratio");
        return Utils.multiplyAndDivideFloor(amount, ratio, 10 ** decimals);
    }

    function _depositErc20(address fromToken, uint256 toChain, address toAddress, uint256 totalAmount) internal {
        /* sender is our from address because he is locking funds */
        address fromAddress = address(msg.sender);
        InternetBondType bondType = getBondType(fromToken);
        /* check allowance and transfer tokens */
        {
            uint256 balanceBefore = IERC20(fromToken).balanceOf(address(this));
            uint256 allowance = IERC20(fromToken).allowance(fromAddress, address(this));
            require(totalAmount <= allowance, "insufficient allowance");
            require(IERC20(fromToken).transferFrom(fromAddress, address(this), totalAmount), "can't transfer");
            uint256 balanceAfter = IERC20(fromToken).balanceOf(address(this));
            if (bondType != InternetBondType.REBASING_BOND) {
                // Assert that enough coins were transferred to bridge
                require(balanceAfter >= balanceBefore + totalAmount, "incorrect behaviour");
            } else {
                // For rebasing internet bonds we can't assert that exactly totalAmount will be transferred
                require(balanceAfter >= balanceBefore, "incorrect behaviour");
            }
        }
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        uint256 chain = Utils.currentChain();
        uint256 amt;
        if (bondType != InternetBondType.REBASING_BOND) {
            amt = _amountErc20Token(fromToken, totalAmount);
        } else {
            amt = _amountErc20Bond(fromToken, totalAmount, getNativeRatio(fromToken));
        }
        address toToken;
        if (bondType == InternetBondType.NOT_BOND) {
            toToken = _bridgeRouter.peggedTokenAddress(address(toBridge), fromToken);
        } else {
            toToken = _bridgeRouter.peggedBondAddress(address(toBridge), fromToken);
        }
        Metadata memory metaData = Metadata(
            Utils.stringToBytes32(IERC20Extra(fromToken).symbol()),
            Utils.stringToBytes32(IERC20Extra(fromToken).name()),
            chain,
            fromToken,
            createBondMetadata(0, bondType)
        );
        /* emit event with all these params */
        emit DepositLocked(
            toChain,
            fromAddress, // who send these funds
            toAddress, // who can claim these funds in "toChain" network
            fromToken, // this is our current native token (can be ETH, CLV, DOT, BNB or something else)
            toToken, // this is an address of our target pegged token
            amt, // how much funds was locked in this contract
            metaData // meta information about
        );
    }

    function _peggedDestinationErc20Token(address fromToken, address origin, uint256 toChain, uint originChain) internal view returns (address) {
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        require(_peggedTokenOrigin[fromToken] == origin, "non-pegged contract not supported");
        if (toChain == originChain) {
            return _peggedTokenOrigin[fromToken];
        } else {
            return _bridgeRouter.peggedTokenAddress(address(toBridge), origin);
        }
    }

    function _peggedDestinationErc20Bond(address fromToken, address origin, uint256 toChain, uint originChain) internal view returns (address) {
        /* lets determine target bridge contract */
        address toBridge = _bridgeAddressByChainId[toChain];
        require(toBridge != address(0x00), "bad chain");
        require(_peggedTokenOrigin[fromToken] == origin, "non-pegged contract not supported");
        if (toChain == originChain) {
            return _peggedTokenOrigin[fromToken];
        } else {
            return _bridgeRouter.peggedBondAddress(address(toBridge), origin);
        }
    }

    function _amountErc20Token(address fromToken, uint256 totalAmount) internal returns (uint256) {
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        require(IERC20Extra(fromToken).decimals() <= 18, "decimals overflow");
        totalAmount *= (10 ** (18 - IERC20Extra(fromToken).decimals()));
        return totalAmount;
    }

    function _amountErc20Bond(address fromToken, uint256 totalAmount, uint256 nativeRatio) internal returns (uint256) {
        /* lets pack ERC20 token meta data and scale amount to 18 decimals */
        uint8 decimals = IERC20Extra(fromToken).decimals();
        require(decimals <= 18, "decimals overflow");
        uint256 totalShares = _nativeAmountToShares(totalAmount, nativeRatio, decimals);
        totalShares *= (10 ** (18 - decimals));
        return totalShares;
    }

    function _currentChainNativeMetaData() internal view returns (Metadata memory) {
        return _nativeTokenMetadata;
    }

    // WITHDRAWAL FUNCTIONS

    function withdraw(
        bytes calldata /* encodedProof */,
        bytes calldata rawReceipt,
        bytes memory proofSignature
    ) external nonReentrant whenNotPaused override {
        uint256 proofOffset;
        uint256 receiptOffset;
        assembly {
            proofOffset := add(0x4, calldataload(4))
            receiptOffset := add(0x4, calldataload(36))
        }
        /* we must parse and verify that tx and receipt matches */
        (EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType) = EthereumVerifier.parseTransactionReceipt(receiptOffset);
        require(state.chainId == Utils.currentChain(), "receipt points to another chain");
        ProofParser.Proof memory proof = ProofParser.parseProof(proofOffset);
        require(_bridgeAddressByChainId[proof.chainId] == state.contractAddress, "crosschain event from not allowed contract");
        state.receiptHash = keccak256(rawReceipt);
        proof.status = 0x01; // execution must be successful
        proof.receiptHash = state.receiptHash; // ensure that rawReceipt is preimage of receiptHash
        bytes32 hash;
        assembly {
            hash := keccak256(proof, 0x100)
        }
        // we can trust receipt only if proof is signed by consensus
        require(ECDSAUpgradeable.recover(hash, proofSignature) == _consensusAddress, "bad signature");
        // withdraw funds to recipient
        _withdraw(state, pegInType, hash);
    }

    function _withdraw(EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType, bytes32 proofHash) internal {
        /* make sure these proofs wasn't used before */
        require(!_usedProofs[proofHash], "proof already used");
        _usedProofs[proofHash] = true;
        if (state.toToken == _nativeTokenMetadata.originAddress) {
            _withdrawNative(state);
        } else if (pegInType == EthereumVerifier.PegInType.Lock) {
            _withdrawPegged(state, state.fromToken);
        } else if (state.toToken != state.originToken) {
            // origin token is not deployed by our bridge so collision is not possible
            _withdrawPegged(state, state.originToken);
        } else {
            _withdrawErc20(state);
        }
    }

    function _withdrawNative(EthereumVerifier.State memory state) internal {
        state.toAddress.transfer(state.totalAmount);
        emit WithdrawUnlocked(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    function _withdrawPegged(EthereumVerifier.State memory state, address origin) internal {
        /* create pegged token if it doesn't exist */
        Metadata memory metadata = EthereumVerifier.getMetadata(state);
        InternetBondType bondType = InternetBondType(uint8(metadata.bondMetadata[1]));
        if (bondType == InternetBondType.NOT_BOND) {
            _factoryPeggedToken(state.toToken, metadata);
        } else {
            _factoryPeggedBond(state.toToken, metadata);
        }
        /* mint tokens (NB: mint for bonds accepts amount in shares) */
        IERC20Mintable(state.toToken).mint(state.toAddress, state.totalAmount);
        /* emit peg-out event (its just informative event) */
        emit WithdrawMinted(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    function _withdrawErc20(EthereumVerifier.State memory state) internal {
        Metadata memory metadata = EthereumVerifier.getMetadata(state);
        InternetBondType bondType = InternetBondType(uint8(metadata.bondMetadata[1]));
        /* we need to rescale this amount */
        uint8 decimals = IERC20Extra(state.toToken).decimals();
        require(decimals <= 18, "decimals overflow");
        uint256 scaledAmount = state.totalAmount / (10 ** (18 - decimals));
        if (bondType == InternetBondType.REBASING_BOND) {
            scaledAmount = Utils.multiplyAndDivideCeil(scaledAmount, 10 ** decimals, getNativeRatio(state.toToken));
        }
        /* transfer tokens and make sure behaviour is correct (just in case) */
        uint256 balanceBefore = IERC20(state.toToken).balanceOf(state.toAddress);
        require(IERC20Upgradeable(state.toToken).transfer(state.toAddress, scaledAmount), "can't transfer");
        uint256 balanceAfter = IERC20(state.toToken).balanceOf(state.toAddress);
        require(balanceBefore <= balanceAfter, "incorrect behaviour");
        /* emit peg-out event (its just informative event) */
        emit WithdrawUnlocked(
            state.receiptHash,
            state.fromAddress,
            state.toAddress,
            state.fromToken,
            state.toToken,
            state.totalAmount
        );
    }

    // OWNER MAINTENANCE FUNCTIONS (owner functions will be reduced in future releases)

    function factoryPeggedToken(uint256 fromChain, Metadata calldata metaData) external onlyOwner override {
        // make sure this chain is supported
        require(_bridgeAddressByChainId[fromChain] != address(0x00), "bad contract");
        // calc target token
        address toToken = _bridgeRouter.peggedTokenAddress(address(this), metaData.originAddress);
        require(_peggedTokenOrigin[toToken] == address(0x00), "already exists");
        // deploy new token (its just a warmup operation)
        _factoryPeggedToken(toToken, metaData);
    }

    function _factoryPeggedToken(address toToken, Metadata memory metaData) internal returns (IERC20Mintable) {
        address fromToken = metaData.originAddress;
        /* if pegged token exist we can just return its address */
        if (_peggedTokenOrigin[toToken] != address(0x00)) {
            return IERC20Mintable(toToken);
        }
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        (bool success, bytes memory returnValue) = address(_bridgeRouter).delegatecall(
            abi.encodeWithSignature("factoryPeggedToken(address,address,(bytes32,bytes32,uint256,address,bytes32),address)", fromToken, toToken, metaData, address(this))
        );
        if (!success) {
            // preserving error message
            uint256 returnLength = returnValue.length;
            assembly {
                revert(add(returnValue, 0x20), returnLength)
            }
        }
        /* now we can mark this token as pegged */
        _peggedTokenOrigin[toToken] = fromToken;
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function factoryPeggedBond(uint256 fromChain, Metadata calldata metaData) external onlyOwner override {
        // make sure this chain is supported
        require(_bridgeAddressByChainId[fromChain] != address(0x00), "bad contract");
        // calc target token
        address toToken = _bridgeRouter.peggedBondAddress(address(this), metaData.originAddress);
        require(_peggedTokenOrigin[toToken] == address(0x00), "already exists");
        // deploy new token (its just a warmup operation)
        _factoryPeggedBond(toToken, metaData);
    }

    function _factoryPeggedBond(address toToken, Metadata memory metaData) internal returns (IERC20Mintable) {
        address fromToken = metaData.originAddress;
        if (_peggedTokenOrigin[toToken] != address(0x00)) {
            return IERC20Mintable(toToken);
        }
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        (bool success, bytes memory returnValue) = address(_bridgeRouter).delegatecall(
            abi.encodeWithSignature("factoryPeggedBond(address,address,(bytes32,bytes32,uint256,address,bytes32),address,address)", fromToken, toToken, metaData, address(this), address(_internetBondRatioFeed))
        );
        if (!success) {
            // preserving error message
            uint256 returnLength = returnValue.length;
            assembly {
                revert(add(returnValue, 0x20), returnLength)
            }
        }
        /* now we can mark this token as pegged */
        _peggedTokenOrigin[toToken] = fromToken;
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function addAllowedContract(address allowedContract, uint256 toChain) public onlyOwner {
        require(_bridgeAddressByChainId[toChain] == address(0x00), "already allowed");
        require(toChain > 0, "chain id must be positive");
        _bridgeAddressByChainId[toChain] = allowedContract;
        emit ContractAllowed(allowedContract, toChain);
    }

    function removeAllowedContract(uint256 toChain) public onlyOwner {
        require(_bridgeAddressByChainId[toChain] != address(0x00), "already disallowed");
        require(toChain > 0, "chain id must be positive");
        address wasContract = _bridgeAddressByChainId[toChain];
        delete _bridgeAddressByChainId[toChain];
        emit ContractDisallowed(wasContract, toChain);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function changeConsensus(address consensus) public onlyOwner {
        require(consensus != address(0x0), "zero address disallowed");
        _consensusAddress = consensus;
        emit ConsensusChanged(_consensusAddress);
    }

    function changeRouter(address router) public onlyOwner {
        require(router != address(0x0), "zero address disallowed");
        _bridgeRouter = BridgeRouter(router);
        // We don't have special event for router change since it's very special technical contract
        // In future changing router will be disallowed
    }
}
