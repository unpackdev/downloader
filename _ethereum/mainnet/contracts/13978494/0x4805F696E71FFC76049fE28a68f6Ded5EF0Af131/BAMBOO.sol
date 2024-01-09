// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface IPandaNFT {
    function balanceOf(address _user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

contract BAMBOO is AccessControl, Ownable, ERC20 {
    using ECDSA for bytes32;

    /** CONTRACTS */
    IPandaNFT public pandaNFT;

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /** CLAIMING */
    uint256 public initialIssuance = 0 * 10**18;
    uint256 public issuanceRate = 10 * 10**18;
    uint256 public issuancePeriod = 1 days;    
    uint256 public deployedTime = block.timestamp;
    uint256 public claimEndTime = block.timestamp + 365 days * 10;

    uint256 public maxClaimLatency = 10 minutes;
    uint256 public maxClaimPerTx = 10000 * 10**18;

    /* SECURITY */
    address public distributor;
    bool useDistributor = false;
    bool useMaxClaimPerTx = false;

    /** SIGNATURES */
    address public signerWallet;
    mapping(address => uint256) public addressToNonce;

    /** EVENTS */
    event ClaimedReward(address indexed user, uint256 reward, uint256 nonce, uint256 timestamp, bytes signature);
    event setPandaNFTEvent(address pandaNFT);
    event setIssuanceRateEvent(uint256 issuanceRate);
    event setIssuancePeriodEvent(uint256 issuancePeriod);
    event setMaxClaimLatencyEvent(uint256 maxClaimLatency);
    event setClaimEndTimeEvent(uint256 claimEndTIme);
    event setInitialIssuanceEvent(uint256 initialIssuance);
    event setDistributorEvent(address distributor);
    event setUseDistributorEvent(bool useDistributor);
    event setUseMaxClaimPerTxEvent(bool useMaxClaimPerTx);

    /** MODIFIERS */
    modifier canClaim(uint256 amount, uint256 nonce, uint256 timestamp, bytes memory signature) {
        require(block.timestamp <= claimEndTime, "CLAIM ENDED");
        require(pandaNFT.balanceOf(msg.sender) > 0, "BALANCE ZERO");
        require(block.timestamp - timestamp <= maxClaimLatency, "TX TOOK TOO LONG");
        if (useMaxClaimPerTx) {
            require(amount <= maxClaimPerTx, "CANNOT CLAIM MORE");
        }        

        bytes32 message = keccak256(abi.encodePacked(msg.sender, amount, addressToNonce[msg.sender], timestamp, address(this))).toEthSignedMessageHash();
        require(addressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        require(recoverSigner(message, signature) == signerWallet, "SIGNATURE NOT FROM SIGNER WALLET");
        _;
    }

    constructor(
        address _panda
    ) ERC20("BAMBOO", "$BAMBOO") Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        pandaNFT = IPandaNFT(_panda);
    }

    /** SIGNATURE VERIFICATION */

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    /** CLAIMING */

    function claim(uint256 amount, uint256 nonce, uint256 timestamp, bytes memory signature) external canClaim(amount, nonce, timestamp, signature) {
        addressToNonce[msg.sender] = addressToNonce[msg.sender] + 1;
        if (useDistributor) {
            transferFrom(distributor, msg.sender, amount);
        } else {
            _mint(msg.sender, amount);
        }        
        emit ClaimedReward(msg.sender, amount, nonce, timestamp, signature);
    }

    /** ROLE BASED */

    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
    }


    /** OWNER */

    function setPandaNFT(address _newPanda) external onlyOwner {
        pandaNFT = IPandaNFT(_newPanda);
        emit setPandaNFTEvent(_newPanda);
    }

    function setIssuanceRate(uint256 _newIssuanceRate) external onlyOwner {
        issuanceRate = _newIssuanceRate;
        emit setIssuanceRateEvent(_newIssuanceRate);
    }

    function setIssuancePeriod(uint256 _newIssuancePeriod) external onlyOwner {
        issuancePeriod = _newIssuancePeriod;
        emit setIssuancePeriodEvent(_newIssuancePeriod);
    }

    function setMaxClaimLatency(uint256 _newMaxClaimLatency) external onlyOwner {
        maxClaimLatency = _newMaxClaimLatency;
        emit setMaxClaimLatencyEvent(_newMaxClaimLatency);
    }

    function setMaxClaimPerTx(uint256 _newMaxClaimPerTx) external onlyOwner {
        maxClaimPerTx = _newMaxClaimPerTx;        
    }

    function setClaimEndTime(uint256 _newClaimEndTime) external onlyOwner {
        claimEndTime = _newClaimEndTime;
        emit setClaimEndTimeEvent(_newClaimEndTime);
    }

    function setInitialIssuance(uint256 _newInitialIssuance) external onlyOwner {
        initialIssuance = _newInitialIssuance;
        emit setInitialIssuanceEvent(_newInitialIssuance);
    }

    function setSignerWallet(address _newSignerWallet) external onlyOwner {
        signerWallet = _newSignerWallet;
    }

    function setDistributor(address _newDistributor) external onlyOwner {
        distributor = _newDistributor;
        emit setDistributorEvent(_newDistributor);
    }

    function setUseDistributor(bool _newUseDistributor) external onlyOwner {
        useDistributor = _newUseDistributor;
        emit setUseDistributorEvent(_newUseDistributor);
    }

    function setUseMaxClaimPerTx(bool _newUseMaxClaimPerTx) external onlyOwner {
        useMaxClaimPerTx = _newUseMaxClaimPerTx;
        emit setUseMaxClaimPerTxEvent(_newUseMaxClaimPerTx);
    }
}