// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./OldMasterMemes.sol";
import "./OldMasterMemesErrors.sol";
import "./Frames.sol";

/**
 * @title OldMasterMemes Wrapper contract
 */
contract OldMasterMemesWrapper is Ownable {

    uint256 public maxOmm;
    bool public saleIsActive;
    bool public communitySaleIsActive;

    OldMasterMemes private _omm_contract;

    mapping(address => uint256) public lastPurchase;
    mapping(bytes32 => bool) public usedLink;

    //////////////////////
    // Modifiers
    //////////////////////

    modifier whenSaleIsActive {
        if(!saleIsActive) revert SaleInactive();
        _;
    }

    modifier whenCommunitySaleIsActive() {
        if(!communitySaleIsActive) revert CommunitySaleInactive();
        _;
    }

    /////////////////////
    // Events
    /////////////////////

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /////////////////////
    // Public Functions
    /////////////////////

    function mintOMM(uint256 amount) external payable whenSaleIsActive {
        if(amount > _omm_contract.maxPerMint()) revert AmountExceedsMaxPerMint();
        if(_omm_contract.mintIndex() + amount > maxOmm) revert ExceedCap();
        if(_omm_contract.mintPrice() * amount > msg.value) revert EtherValueIncorrect();
        if(lastPurchase[msg.sender] >= block.timestamp - _omm_contract.mintInterval()) revert ExceedsMaxMintsForMintInterval();

        _omm_contract.mintForCommunity(msg.sender, amount);

        lastPurchase[msg.sender] = block.timestamp;
    }

    function communitySaleMintOMM(
        address wallet,
        uint256 maxAmount,
        uint256 timestamp,
        bytes memory signature,
        uint256 amount
    ) external payable whenCommunitySaleIsActive {
        if(_omm_contract.balanceOf(msg.sender) + amount > _omm_contract.maxPerUser()) revert AmountExceedsMaxPerUser();
        if(amount > maxAmount) revert AmountExceedsMax();
        if(_omm_contract.mintIndex() + amount > maxOmm) revert AmountExceedsCommunityMax();
        if(_omm_contract.mintPricePresale() * amount > msg.value) revert EtherValueIncorrect();
        if(msg.sender != wallet) revert WalletSenderMismatch();
        if(!_verifySignature(wallet, maxAmount, timestamp, signature)) revert InvalidSignature();
        bytes32 linkHash = keccak256(signature);
        if(usedLink[linkHash]) revert CommunityLinkAlreadyUsed();

        _omm_contract.mintForCommunity(msg.sender, amount);

        usedLink[linkHash] = true;
    }

    // ------------------
    // Owner functions
    // ------------------

    function initialize(
        address _old_contract_address,
        uint256 _maxOmm
    )  external onlyOwner {
        if(address(_omm_contract) != address(0)) revert ContractAlreadyInitialized();
        if(_old_contract_address == address(0)) revert EmptyAddress();
        if(_maxOmm == 0) revert MaxOmmIsZero();
        _omm_contract = OldMasterMemes(_old_contract_address);
        bool originalContractSaleIsActive = _omm_contract.saleIsActive();
        if(originalContractSaleIsActive) revert SaleOfOriginalContractActive();
        maxOmm = _maxOmm;
        saleIsActive = false;
        communitySaleIsActive = false;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        _omm_contract.setMaxPerMint(_maxPerMint);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        _omm_contract.setMintPrice(_mintPrice);
    }

    function setMintPriceCommunity(uint256 _mintPriceCommunity) external onlyOwner {
        _omm_contract.setMintPricePresale(_mintPriceCommunity);
    }

    function setMintInterval(uint256 _mintInterval) external onlyOwner {
        _omm_contract.setMintInterval(_mintInterval);
    }

    function setMaxPerUser(uint256 _maxPerUser) external onlyOwner {
        _omm_contract.setMaxPerUser(_maxPerUser);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        _omm_contract.setBaseUri(_baseUri);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _omm_contract.setTokenURI(tokenId, _tokenURI);
    }

    function setCommunitySaleSigner(address _communitySaleSigner) external onlyOwner {
        _omm_contract.setPresaleSigner(_communitySaleSigner);
    }

    function mintForCommunity(address to, uint256 numberOfTokens) external onlyOwner {
        //TODO: Check if needed / more or less expensive
        if(to == address(0)) revert EmptyAddress();
        if(_omm_contract.mintIndex() + numberOfTokens > maxOmm) revert ExceedCap();

        _omm_contract.mintForCommunity(to, numberOfTokens);
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        _omm_contract.setProvenanceHash(_provenanceHash);
    }

    function setFramesContract(Frames _framesContract) external onlyOwner {
        _omm_contract.setFramesContract(_framesContract);
    }

    function setUnrevealedTokenUri(string memory _unrevealedTokenUri) external onlyOwner {
        _omm_contract.setUnrevealedTokenUri(_unrevealedTokenUri);
    }

    function reveal() external onlyOwner {
        _omm_contract.reveal();
    }

    function toggleBurnState() external onlyOwner {
        _omm_contract.toggleBurnState();
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function toggleCommunitySaleState() external onlyOwner {
        communitySaleIsActive = !communitySaleIsActive;
    }

    function withdrawOriginalContract(
        address mainShareholder1,
        address mainShareholder2,
        address fivePercentShareholder1,
        address onePercentShareholder1,
        address onePercentShareholder2
    ) external onlyOwner {
        _omm_contract.withdraw(mainShareholder1, mainShareholder2, fivePercentShareholder1, onePercentShareholder1, onePercentShareholder2);
    }

    function emergencyWithdrawOriginalContract() external onlyOwner {
        _omm_contract.emergencyWithdraw();
    }

    function emergencyRecoverTokensOriginalContract(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        _omm_contract.emergencyRecoverTokens(token, receiver, amount);
    }

    function withdraw(
        address mainShareholder1,
        address mainShareholder2,
        address fivePercentShareholder1,
        address onePercentShareholder1,
        address onePercentShareholder2
    ) external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 fivePercentShare = (balance * 5) / 100;
        payable(fivePercentShareholder1).transfer(fivePercentShare);
        uint256 onePercentShare = balance / 100;
        payable(onePercentShareholder1).transfer(onePercentShare);
        payable(onePercentShareholder2).transfer(onePercentShare);
        uint256 restShare = (balance - fivePercentShare - 2 * onePercentShare) / 2;
        payable(mainShareholder1).transfer(restShare);
        payable(mainShareholder2).transfer(restShare);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        if(receiver == address(0)) revert EmptyAddress();
        token.transfer(receiver, amount);
    }

    function freezeMetadata() external onlyOwner {
        _omm_contract.freezeMetadata();
    }

    function freezeProvenance() external onlyOwner {
        _omm_contract.freezeProvenance();
    }

    // ------------------
    // Internal functions
    // ------------------

    function _splitSignature(bytes memory signature)
    private
    pure
    returns (
        uint8,
        bytes32,
        bytes32
    )
    {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        assembly {
            sigR := mload(add(signature, 32))
            sigS := mload(add(signature, 64))
            sigV := byte(0, mload(add(signature, 96)))
        }
        return (sigV, sigR, sigS);
    }

    /**
     * Restores the signer of the signed message and checks if it was signed by the trusted signer and also
     * contains the parameters.
     */
    function _verifySignature(
        address wallet,
        uint256 maxAmount,
        uint256 timestamp,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        (sigV, sigR, sigS) = _splitSignature(signature);
        bytes32 message = keccak256(abi.encodePacked(wallet, maxAmount, timestamp));
        return _omm_contract.presaleSigner() == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)), sigV, sigR, sigS);
    }
}