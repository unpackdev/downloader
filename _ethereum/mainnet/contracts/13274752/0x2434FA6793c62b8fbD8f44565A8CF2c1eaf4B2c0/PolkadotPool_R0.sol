// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

import "./IStakingPool.sol";
import "./IAnkrBond.sol";
import "./IAnkrFuture.sol";
import "./IOwnable.sol";
import "./IPausable.sol";
import "./IBeaconDeployer.sol";

contract PolkadotPool_R0 is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ERC165Upgradeable, IStakingPool {

    address private _operator;
    address private _consensusAddress;
    IBeaconDeployer _bondDeployer;
    IBeaconDeployer _futureDeployer;

    mapping(uint256 => uint256) private _claimUsed;
    mapping(address => address) private _futureForBond;

    function initialize(address operator, address consensusAddress, address bondDeployer, address futureDeployer) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _operator = operator;
        _consensusAddress = consensusAddress;
        _bondDeployer = IBeaconDeployer(bondDeployer);
        _futureDeployer = IBeaconDeployer(futureDeployer);
    }

    function isClaimValid(address token, uint256 claimId, uint256 claimBeforeBlock, uint256 amount, address account, bytes memory signature) public view override returns (bool) {
        if (isClaimUsed(claimId))
            return false;
        if (!_checkClaimSignature(token, claimId, amount, account, claimBeforeBlock, signature))
            return false;
        return true;
    }

    function isClaimUsed(uint256 claimId) public view override returns (bool) {
        return _claimUsed[claimId] != 0;
    }

    function claimBonds(address bond, uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external nonReentrant whenNotPaused override {
        require(_claimUsed[claimId] == 0, "Already claimed");
        _claimUsed[claimId] = 1;
        require(
            _checkClaimSignature(bond, claimId, amount, account, claimBeforeBlock, signature),
            "Invalid claim signature"
        );
        IAnkrBond(bond).mintSharesTo(account, amount);
        emit TokensClaimed(bond, claimId, amount, claimBeforeBlock, account);
    }

    function claimFutures(address future, uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external nonReentrant whenNotPaused override {
        require(_claimUsed[claimId] == 0, "Already claimed");
        _claimUsed[claimId] = 1;
        require(
            _checkClaimSignature(future, claimId, amount, account, claimBeforeBlock, signature),
            "Invalid claim signature"
        );
        IAnkrFuture futureContract = IAnkrFuture(future);
        futureContract.mint(account, block.number + futureContract.getDefaultMaturityBlocks(), amount);
        emit TokensClaimed(future, claimId, amount, claimBeforeBlock, account);
    }

    function burnBond(address bond, uint256 amount, bytes calldata polkadotRecipient) external nonReentrant whenNotPaused override {
        require(substrateAddressIsValid(polkadotRecipient), "incorrect address");
        address account = msg.sender;
        IAnkrBond(bond).burnSharesFrom(account, amount);
        /* We have not deployed futures yet, so just burn tokens with event to redeem them
        IAnkrFuture futureContract = IAnkrFuture(_futureForBond[bond]);
        futureContract.mint(account, block.number + futureContract.getDefaultMaturityBlocks(), amount);
        emit TokensConverted(bond, _futureForBond[bond], account, amount);
        */
        emit TokensBurned(bond, account, polkadotRecipient, amount);
    }

    function burnFuture(address future, uint256 tokenId, bytes calldata polkadotRecipient) external nonReentrant whenNotPaused override {
        require(substrateAddressIsValid(polkadotRecipient), "incorrect address");
        require(IERC721Upgradeable(future).ownerOf(tokenId) == msg.sender, "Can't burn not owned token");
        IAnkrFuture futureContract = IAnkrFuture(future);
        require(futureContract.getMaturity(tokenId) <= block.number, "Can't burn before maturity");
        uint256 amount = futureContract.getAmount(tokenId);
        futureContract.burn(tokenId);
        emit TokensBurned(future, msg.sender, polkadotRecipient, amount);
    }

    function registerBond(string memory name, uint8 decimals) public onlyOperator returns (address) {
        bytes memory call = abi.encodeWithSelector(
            IAnkrBond.initialize.selector, _operator, address(this), name, decimals
        );
        return _bondDeployer.deployNewContract(call);
    }

    function registerFuture(address forBond, string memory name, uint256 defaultMaturity, uint8 decimals, string memory baseUri) public onlyOperator returns (address) {
        require(_futureForBond[forBond] == address(0x00), "This bond already has future");
        // sanity check to prevent accidental mistakes
        require(ERC165CheckerUpgradeable.supportsInterface(forBond, type(IAnkrBond).interfaceId), "Bond contract is not correct");
        bytes memory call = abi.encodeWithSelector(
            IAnkrFuture.initialize.selector, _operator, address(this), name, defaultMaturity, decimals, baseUri
        );
        address future = _futureDeployer.deployNewContract(call);
        _futureForBond[forBond] = future;
        return future;
    }

    function _checkClaimSignature(
        address token, uint256 claimId, uint256 amount, address to, uint256 claimBeforeBlock, bytes memory signature
    ) private view returns (bool) {
        if (block.number > claimBeforeBlock) return false;
        bytes32 payloadHash = keccak256(abi.encode(token, claimId, amount, claimBeforeBlock, to));
        return ECDSAUpgradeable.recover(payloadHash, signature) == _consensusAddress;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IStakingPool).interfaceId;
    }

    function substrateAddressIsValid(bytes calldata rawAddress) public view returns (bool) {
        if (rawAddress.length == 32) {
            // if 32 bytes are specified we interpret them as raw private key
            return true;
        }
        if (rawAddress.length == 35) {
            // we interpret 35 bytes as checksum address with small network id
            uint8 network = uint8(rawAddress[0]);
            if (network != 0x00 && network != 0x02 && network != 0x2a) return false;
            bytes32 publicKey = bytes32(rawAddress[1:33]);
            bytes2 checksum = bytes2(rawAddress[33:35]);
            bytes memory input = hex"0000000c48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b53533538505245000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002800000000000000000000000000000001";
            assembly {
                mstore8(add(input, 107), network)
                mstore(add(input, 108), publicKey)
            }
            uint256 result;
            bytes32[2] memory hash;
            assembly {
                result := staticcall(not(0), 0x09, add(input, 32), 0xd5, hash, 0x40)
            }
            require(result != 0, "checksum calculation fail");
            return hash[0][0] == checksum[0] && hash[0][1] == checksum[1];
        }
        // we do not support any other address formats
        return false;
    }
}
