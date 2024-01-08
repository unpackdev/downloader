// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitterAdjustable.sol";

contract Metanaut is ERC721Enumerable, Pausable, AccessControl, PaymentSplitterAdjustable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    struct Referral {
        address referrerAddress;
        address referralAddress;
        uint256 tokenID;
    }
    
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bytes32 private constant REFERRER_ROLE = keccak256("REFERRER_ROLE");
    bool private mintIsLive_ = false;
    bool private isLocked_ = false;
    bool private isPrerelease_ = true;
    string private prereleaseURI_;
    string private baseURI_;
    string private constant baseURIExtension_ = ".json";
    uint256 private mintPrice_;
    uint256 private maxMintCount_;
    uint256 private maxOwnable_;
    uint256 private maxSupply_;
    mapping(address => uint256) private freeMints_;
    Counters.Counter private tokenIdCounter_;
    mapping(address => Referral[]) private referrers_;
    address[] private referrerKeys_;
    mapping(address => bool) private hasAddedReferrer_;
    address private referralFallbackAddress_;
    mapping(address => bool) private teamAddresses_;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _prereleaseURI,
        string memory _baseURITemp,
        address[] memory _splitAddresses,
        uint256[] memory _splitShares,
        uint256[] memory _referralBaseArgs,
        address _referralFallbackAddress,
        uint256[] memory _mintBaseArgs
    ) ERC721(_tokenName, _tokenSymbol)
    PaymentSplitterAdjustable(_splitAddresses, _splitShares, _referralBaseArgs)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(TEAM_ROLE, _msgSender());

        for(uint256 i = 0; i < _splitAddresses.length; i++) {
            _setupRole(TEAM_ROLE, _splitAddresses[i]);
            teamAddresses_[_splitAddresses[i]] = true;
        }

        setPrereleaseURI(_prereleaseURI);
        setBaseURI(_baseURITemp);
        setReferralFallbackAddress(_referralFallbackAddress);
        setMintPrice(_mintBaseArgs[0]);
        setMaxMintCount(_mintBaseArgs[1]);
        setMaxOwnable(_mintBaseArgs[2]);
        setMaxSupply(_mintBaseArgs[3]);
    }

    function getIsPaused() external view returns(bool) {
        return paused();
    }

    function setIsPaused(bool _isPaused) external onlyRole(ADMIN_ROLE) {
        require(paused() != _isPaused, "Contract is already in that paused state");

        if (_isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    modifier whenNotLocked {
        require(!isLocked_);
        _;
    }

    modifier whenNotLockedOrPaused {
        require(!isLocked_ && !paused());
        _;
    }

    function getIsLocked() external view whenNotPaused returns(bool) {
        return isLocked_;
    }

    function setIsLocked(bool _isLocked) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(isLocked_ != _isLocked, "Contract is already in that locked state");

        isLocked_ = _isLocked;
    }

    modifier whenMintIsLive {
        require(mintIsLive_);
        _;
    }

    function getMintIsLive() external view whenNotPaused returns(bool) {
        return mintIsLive_;
    }

    function setMintIsLive(bool _mintIsLive) external whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        require(mintIsLive_ != _mintIsLive, "Contract is already in that live state");

        mintIsLive_ = _mintIsLive;
    }

    function getIsPrerelease() external view whenNotPaused returns(bool) {
        return isPrerelease_;
    }

    function setIsPrerelease(bool _isPrerelease) external whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        isPrerelease_ = _isPrerelease;
    }

    function getPrereleaseURI() external view whenNotPaused returns(string memory) {
        return prereleaseURI_;
    }

    function setPrereleaseURI(string memory _prereleaseURI) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        prereleaseURI_ = _prereleaseURI;
    }

    function getBaseURI() external view whenNotPaused returns (string memory) {
        return string(_baseURI());
    }
    
    function _baseURI() internal view override whenNotPaused returns (string memory) {
        return string(baseURI_);
    }

    function setBaseURI(string memory _baseURITemp) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        baseURI_ = _baseURITemp;
    }

    function getTokenURI(uint256 _tokenID) external view whenNotPaused returns (string memory) {
        return string(tokenURI(_tokenID));
    }
    
    function tokenURI(uint256 tokenId) public view virtual override whenNotPaused returns (string memory) {
        if(isPrerelease_) { 
            return string(prereleaseURI_); 
        }

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), string(baseURIExtension_))) : "";
    }

    function getMintPrice() public view whenNotPaused returns(uint256) {
        return mintPrice_;
    }

    function setMintPrice(uint256 _mintPrice) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        mintPrice_ = _mintPrice;
    }

    function getMaxMintCount() public view whenNotPaused returns(uint256) {
        return maxMintCount_;
    }

    function setMaxMintCount(uint256 _maxMintCount) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        maxMintCount_ = _maxMintCount;
    }

    function getMaxOwnable() public view whenNotPaused returns(uint256) {
        return maxOwnable_;
    }

    function setMaxOwnable(uint256 _maxOwnable) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        maxOwnable_ = _maxOwnable;
    }

    function getMaxSupply() public view whenNotPaused returns(uint256) {
        return maxSupply_;
    }

    function setMaxSupply(uint256 _maxSupply) public whenNotLockedOrPaused onlyRole(ADMIN_ROLE) {
        maxSupply_ = _maxSupply;
    }

    function getTotalSupply() public view whenNotPaused returns(uint256) {
        return totalSupply();
    }

    function mintToken(uint256 _mintCount, address _referrerAddress) external payable whenMintIsLive whenNotPaused {
        mintTokenTo(_mintCount, _referrerAddress, _msgSender());
    }

    function mintTokenTo(uint256 _mintCount, address _referrerAddress, address _to) public payable whenMintIsLive whenNotPaused {
        require(_mintCount > 0, "Must mint at least 1, increase mintCount");
        require(_mintCount + getTotalSupply() <= getMaxSupply(), "Minting too many, decrease mintCount or check all have not been minted");
        require(balanceOf(_msgSender()) + _mintCount <= getMaxOwnable(), "Own too many, decrease mintCount or check you own fewer than the max owned");

        if (freeMints_[_msgSender()] >= _mintCount) {
            freeMints_[_msgSender()] -= _mintCount;
        } else {
            require(_mintCount <= getMaxMintCount(), "Minting too many, decrease mintCount");
            require(msg.value >= getMintPrice() * _mintCount, "Value sent must be higher to mint the mintCount");

            if (_referrerAddress == address(0) || teamAddresses_[_referrerAddress]) {
                _referrerAddress = getReferralFallbackAddress();
            }
            if (!hasAddedReferrer_[_referrerAddress]) {
                _setupRole(REFERRER_ROLE, _referrerAddress);
            }
        }

        for (uint256 i = 0; i < _mintCount; i++) {
            uint256 tokenID = tokenIdCounter_.current();
            tokenIdCounter_.increment();
            setReferral(_referrerAddress, _msgSender(), tokenID);
            _safeMint(_to, tokenID);
        }
    }

    function getFreeMints(address _account) public view whenNotPaused returns(uint256) {
        return freeMints_[_account];
    }

    function setFreeMints(address _account, uint256 _count) external whenNotPaused onlyRole(ADMIN_ROLE) {
        freeMints_[_account] = _count;
    }

    function getReferrals(address _referrer) public view whenNotPaused returns(Referral[] memory) {
        return referrers_[_referrer];
    }

    function getAllReferrals() public view whenNotPaused returns(Referral[] memory) {
        uint256 totalReferralCount;
        uint256 tempReferralCount;

        for(uint256 i = 0; i < referrerKeys_.length; i++)
        {
            for(uint256 j = 0; j < referrers_[referrerKeys_[i]].length; j++)
            {
                totalReferralCount++;
            }
        }

        Referral[] memory referralsTemp = new Referral[](totalReferralCount);

        for(uint256 i = 0; i < referrerKeys_.length; i++)
        {
            for(uint256 j = 0; j < referrers_[referrerKeys_[i]].length; j++)
            {
                referralsTemp[tempReferralCount] = referrers_[referrerKeys_[i]][j];
                tempReferralCount++;
            }
        }

        return referralsTemp;
    }

    function getAllReferralsCount() public view whenNotPaused returns(uint256) {
        return getAllReferrals().length;
    }

    function getReferralFallbackAddress() public view whenNotPaused returns(address) {
        return referralFallbackAddress_;
    }

    function setReferralFallbackAddress(address _referralFallbackAddress) public whenNotPaused onlyRole(ADMIN_ROLE) {
        referralFallbackAddress_ = _referralFallbackAddress;
    }

    function setReferral(address _referrer, address _referral, uint256 _tokenID) internal whenNotPaused {
        if(!hasAddedReferrer_[_referrer]) {
            hasAddedReferrer_[_referrer] = true;
            referrerKeys_.push(_referrer);
        }

        referrers_[_referrer].push(Referral(_referrer, _referral, _tokenID));
    }

    function getShares(address _account) external view whenNotPaused returns(uint256) {
        return shares(_account);
    }

    function setShares(address _account, uint256 _shares) external whenNotPaused onlyRole(ADMIN_ROLE) {
        setPayee(_account, _shares);
    }

    function getSharesPending(address _account) external view returns(uint256) {
        return calculateShares(_account, getTotalSupply());
    }

    function getSharesPotential(address _account) external view returns(uint256) {
        return calculateShares(_account, getMaxSupply());
    }

    function calculateShares(address _referrerAddress, uint256 _supply) internal view returns(uint256) {
        uint256 referralTotal = getReferrals(_referrerAddress).length;
        uint256 referralPercentWeighted = referralTotal.mul(getReferralBaseWeight()) + referralTotal.mul(referralTotal);
        referralPercentWeighted = referralPercentWeighted.mul(getReferralReservedShares());
        referralPercentWeighted = referralPercentWeighted.div(getReferralBaseWeight() + 1);

        uint256 referrersPercentWeightedTotal;

        for(uint256 i = 0; i < referrerKeys_.length; i++)
        {
            uint256 _referralTotal = getReferrals(referrerKeys_[i]).length;
            uint256 _referralPercentWeighted = _referralTotal.mul(getReferralBaseWeight()) + _referralTotal.mul(_referralTotal);
            _referralPercentWeighted = _referralPercentWeighted.mul(getReferralReservedShares());
            _referralPercentWeighted = _referralPercentWeighted.div(getReferralBaseWeight() + 1);

            referrersPercentWeightedTotal += _referralPercentWeighted;
        }

        uint256 shares = referralPercentWeighted.mul(getReferralReservedShares());
        shares = shares.div(referrersPercentWeightedTotal);

        uint256 shareUnlockWeight = _supply.mul(getReferralShareUnlockBaseWeight());
        shareUnlockWeight = shareUnlockWeight.div(getMaxSupply());
        shareUnlockWeight = shareUnlockWeight.mul(shareUnlockWeight);
        shareUnlockWeight = shareUnlockWeight.div(getReferralShareUnlockBaseWeight());

        shares = shares.mul(shareUnlockWeight);
        shares = shares.div(getReferralShareUnlockBaseWeight());
        shares = shares.mul(getAllReferralsCount());
        shares = shares.div(_supply);

        return shares;
    }

    function setReferrerShares(address _account, uint256 _shares) private whenNotPaused onlyRole(REFERRER_ROLE) {
        setPayeeReferrer(_account, _shares);
    }

    // Shares are not allocated until withdraw time, so we calculate with _pendingPaymentAtWithdraw
    function getPendingPayment(address _referrerAddress) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return calculatePendingPaymentPotential(calculateShares(_referrerAddress, getTotalSupply()), totalReceived, getWithdrawn(_referrerAddress));
    }

    function getPendingPaymentPotential(address _referrerAddress) internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased() + (getMintPrice() * (getMaxSupply() - getTotalSupply()));
        return calculatePendingPaymentPotential(calculateShares(_referrerAddress, getMaxSupply()), totalReceived, getWithdrawn(_referrerAddress));
    }

    function getPendingPaymentAndTotalWithdrawn(address _referrerAddress) external view returns (uint256) {
        return getWithdrawn(_referrerAddress) + getPendingPayment(_referrerAddress);
    }

    function getPendingPaymentAndTotalWithdrawnPotential(address _referrerAddress) external view returns (uint256) {
        return getWithdrawn(_referrerAddress) + getPendingPaymentPotential(_referrerAddress);
    }

    function getWithdrawn(address _referrerAddress) public view returns (uint256) {
        return released(_referrerAddress);
    }
    
    function withdraw() external whenNotPaused onlyRole(TEAM_ROLE) {
        withdrawTo(payable(_msgSender()));
    }

    function withdrawReferrer() external whenNotPaused onlyRole(REFERRER_ROLE) {
        setReferrerShares(_msgSender(), calculateShares(_msgSender(), getTotalSupply()));
        withdrawTo(payable(_msgSender()));
    }

    function withdrawTo(address payable _account) private whenNotPaused {
        super.release(_account);
    }

    function withdrawTokenTo(IERC20 _token, address _account) external whenNotPaused onlyRole(ADMIN_ROLE) {
        super.release(_token, _account);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) whenNotPaused returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}