// SPDX-License-Identifier: MIT

/**
################&&&&&###############&&&&&########&&&&&###############&&&&&######
######&&&&&####&GJJY#&#############&GJJY#&######&#YJJG&#############&#YJJG&#####
###############&Y  .B&#############&Y  .B&######&B.  Y&#############&B.  Y&#####
#####&5::^B&###&BPPG###&&&&########&BPPG&&&&######GPP#&&&######&&&&###GPPB&#####
#####&5^^~#&####&&&&##&BBBB&########&&&#PPPB&#####&&&GPPG&####&GPPG&##&&&&######
######&&&&&&&&########&5JJ5&##########&B   Y&#######&~  ~&##&&&~  ~&&&##########
######&&&#!!~P&&&#####&PYYP&########&&&#5YYB&&&#####&PYYP&&#!~!.  .!~!#&########
#######GGP.  JBGB#####&5JJ5&#########################&&&&#&B:..    ..:B&########
#####&Y         ~&####&!..!&##&&&&&&BYYYYYYYYYP&&&&&&##########~  ~#############
#####&G???   ~??Y&###&&!  !&&#GPGGGG5YYYYYYYYY5GGGGGPB&######&&Y??Y&&###########
######&&&#:  5@&&######!  !###YYYYYYYYYYYYYYYYYYYYYYYG#########&&&&#############
##########GGG###&&&#^::.  ~5Y5B######################PYYP&&&##########&&&#######
##########&&&##&GYYY.  ^~^7PPP#######################GPPPGGB##########5YYG######
###############&Y   .. 7YYP&&#########################&&BJYY########&B   Y&#####
###############&Y ..7??PBBB######?^^?#########5^~~B####&BYYY##########PP5B######
###############&Y ..JYYB&&#######~  ~#########Y  .B####&BYYY##########&&&#######
###&&&&########&Y ..JYYB&########~  ~#########Y  .B####&BYYY####################
###J!!J########&Y ..JYYB&########~  ~#########Y  .B####&BYYY####################
##&!  !&#######&Y ..JYYB&########~  ~#########Y  .B####&BYYY#######BBB##########
###BBBB########&Y ..JYYB&&#######~  ~#########Y  .B####&BYYY###&&&5..:#&&#######
###############&Y ..!7!5GGB######J!!J#########P!!7B####&BYYY###5JJ!   ?JJG######
###############&Y ..   7YJP&###########################&BYYY##&~         Y&#####
#####&5::^B#####BPGP:..:::!55P#&&GPPPPPPPPPPPPPPPG##&G55PBBB###GPG?   5PPB######
#####&5^^~B##BBBBBBG:.... ^?7?GBBP5555555555555555BBBY77Y&######&&P^~!#&&#######
#############5JYYYYJ........ .JYYYYYYYYYYYYYYYYYYYYYY~. !&&#####################
#############5YYYYYJ..........^~~~~~~~~~~~~~~~~~~~~~~:..:!!7####################
#############5YYYYYJ.....................................  .PGGB#########BGGB###
#############5YYYYYJ...........................................5&########~  ~###
#############5YYYYYJ.......................................... Y&########Y??Y###
####BB####BB#5JYYYYJ...........................................Y&##BBB####&&####
###!..!##B^:::::::::............... ^JJJYYYJJJ7 ...............Y&&Y..:B#########
###?~~?##B:  ....................^~^7YYY555YYY?^~^............ Y##5~~!B#########
#########B:  ....................?YYY555555555YYYJ............ Y&###############
##########PPPJ?????7.............?5Y55555555555Y5Y:........... Y################
############&PYYYYYJ.............?555555555555555Y:............Y#########GPPG###
#############5YYYYYJ.............?YYY555555555YYYJ:............Y#########~  ~###
#############5YYYYYJ.............^~~7YYY555YYYJ~~~.............Y#########5JJ5###
#############5YYYYYJ..............  ~YYY555YYY7  ..............Y##########&&####
 */

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract MooniePunks is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    mapping(address => uint256) public publicMinted;
    mapping(address => uint256) public blended;
    mapping(uint256 => uint256) public premiumMinted;
    mapping(uint256 => uint256) public vipMinted;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply;
    uint256 public maxMintAmount;
    uint256 public maxVipMintAmount;
    uint256 public remainingMembershipMints = 400;
    uint256 public remainingPromoMints = 100;
    uint256 public requiredToBlend;

    bool public paused = true;
    bool public blendEnabled = false;

    address public membershipContract;
    address public ownerWallet;
    address public blendContract;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uriPrefix,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        uint256 _maxVipMintAmount,
        address _ownerWallet,
        address _membershipContract
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        setUriPrefix(_uriPrefix);
        setMaxMintAmount(_maxMintAmount);
        setMaxVipMintAmount(_maxVipMintAmount);
        setMembershipContract(_membershipContract);
        setOwnerWallet(_ownerWallet);
    }

    /// @dev We are ensuring the user cannot mint more than the max amount
    /// that we specify, as well as the current max supply.

    //***************************************************************************
    // MODIFIERS
    //***************************************************************************

    modifier mintCompliance(uint256 _mintAmount, uint256 _maxMintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= _maxMintAmount,
            "Invalid mint amount!"
        );
        require(
            _totalMinted() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    /**
     * @dev We first verify the users membership status, and determine what
     * type of membership they are using to mint.
     *
     * We then check to confirm that the total mint amount does not exceed the
     * remaining membership mints.
     *
     * Finally, we check the token id of their membership NFT, and ensure that it
     * has not been used previously.
     */

    modifier membershipCompliance(
        uint256 _mintAmount,
        uint256 _tokenId,
        MembershipType _memberType
    ) {
        (bool isMember, MembershipType memberType) = verifyMembership(_tokenId);
        require(isMember, "Membership not verified");
        require(
            remainingMembershipMints > _mintAmount,
            "Exceeds membership supply"
        );
        _;
    }

    /// @dev Users cannot mint if contract is paused
    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    //***************************************************************************
    //  ENUMS
    //***************************************************************************

    enum MembershipType {
        PREMIUM,
        VIP
    }

    //***************************************************************************
    //  MINT FUNCTIONS
    //***************************************************************************

    /**
     * @notice The premiumMint and vipMint functions can only be called once per membership token id.
     * We have provided a checkMembershipToken function that will allow users to check to see if a membership token has already minted.
     */

    function premiumMint(uint256 _mintAmount, uint256 _tokenId)
        public
        notPaused
        mintCompliance(_mintAmount, maxMintAmount)
        membershipCompliance(maxMintAmount, _tokenId, MembershipType.PREMIUM)
    {
        require(
            premiumMinted[_tokenId] + _mintAmount <= maxMintAmount,
            "Exceeds max mint amount"
        );
        premiumMinted[_tokenId] += _mintAmount;
        remainingMembershipMints -= _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    /// @notice VIP perks include ten free mints per VIP Card holder.
    function vipMint(uint256 _mintAmount, uint256 _tokenId)
        public
        notPaused
        mintCompliance(_mintAmount, maxVipMintAmount)
        membershipCompliance(maxMintAmount, _tokenId, MembershipType.VIP)
    {
        require(
            vipMinted[_tokenId] + _mintAmount <= maxVipMintAmount,
            "Exceeds max mint amount"
        );
        vipMinted[_tokenId] += _mintAmount;
        remainingMembershipMints -= _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        notPaused
        mintCompliance(_mintAmount, maxMintAmount)
    {
        require(
            _totalMinted() + _mintAmount <=
                maxSupply - remainingReservedSupply(),
            "Max supply exceeded!"
        );
        require(
            publicMinted[_msgSender()] + _mintAmount <= maxMintAmount,
            "Exceeds max mint amount"
        );
        publicMinted[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    /// @dev The owner can mint tokens to any address.
    /// The mintCompliance modifier still governs the maximum amount.

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount, maxMintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    //***************************************************************************
    //  VIEW FUNCTIONS
    //***************************************************************************

    function remainingReservedSupply() public view returns (uint256) {
        return remainingPromoMints + remainingMembershipMints;
    }

    function getMembershipType(uint256 _tokenId, uint256 _maxStandard)
        public
        pure
        returns (MembershipType _memberType)
    {
        MembershipType memberType = _tokenId <= _maxStandard
            ? MembershipType.PREMIUM
            : MembershipType.VIP;
        return memberType;
    }

    /// @dev Verifies that the user has a membership token.

    function verifyMembership(uint256 _tokenId)
        public
        view
        returns (bool _isMember, MembershipType _memberType)
    {
        IERC721 token = IERC721(membershipContract);
        bool isMember = token.ownerOf(_tokenId) == _msgSender();
        return (isMember, getMembershipType(_tokenId, 100));
    }

    /// @dev Checks to see if a membership token as been used to mint already.

    function checkMembershipToken(uint256 _tokenId)
        public
        view
        returns (bool _isMinted)
    {
        if (_tokenId <= 100) {
            return premiumMinted[_tokenId] < maxMintAmount;
        } else {
            return vipMinted[_tokenId] < maxVipMintAmount;
        }
    }

    function verifyOwnershipOfTokens(uint256[] memory _tokenIds)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (ownerOf(_tokenIds[i]) != _msgSender()) {
                return false;
            }
        }
        return true;
    }

    /// @dev Users can blend tokens for reasons...

    function blend(uint256[] calldata _tokenIds) public {
        require(blendEnabled, "Blend is not enabled");
        require(requiredToBlend > 0, "Blend requirement not set");
        require(
            _tokenIds.length == requiredToBlend,
            "Blend must equal the required amount"
        );
        require(
            verifyOwnershipOfTokens(_tokenIds),
            "Membership tokens must be verified"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }
        blended[_msgSender()] += 1;
    }

    function claimBlend(address _origin) public {
        require(
            _msgSender() == blendContract,
            "Only the blend contract can claim blends"
        );
        require(blended[_origin] > 0, "No blends to claim");
        blended[_origin] -= 1;
    }

    /// @dev Returns an array of token IDs that the provided address owns.

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    //***************************************************************************
    //  CRUD FUNCTIONS
    //***************************************************************************

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setMaxVipMintAmount(uint256 _maxVipMintAmount) public onlyOwner {
        maxVipMintAmount = _maxVipMintAmount;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBlendEnabled(bool _state) public onlyOwner {
        blendEnabled = _state;
    }

    function setBlendContract(address _blendContract) public onlyOwner {
        blendContract = _blendContract;
    }

    function setRequiredToBlend(uint256 _requiredToBlend) public onlyOwner {
        requiredToBlend = _requiredToBlend;
    }

    /// @dev Use this in the event that not all CREEK+ members mint, and you
    /// need to dispurse the remaining supply as promotions.

    function disableRedemptions() public onlyOwner {
        remainingPromoMints = remainingPromoMints + remainingMembershipMints;
        remainingMembershipMints = 0;
    }

    function setMembershipContract(address _membershipContract)
        public
        onlyOwner
    {
        membershipContract = _membershipContract;
    }

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = payable(_ownerWallet);
    }

    /// @notice This is a free mint, so theoretially, this should never be called,
    /// but it's here in case funds are ever accidentally sent to the contract.
    function withdraw() public onlyOwner nonReentrant {
        bool success;
        (success, ) = ownerWallet.call{value: address(this).balance}("");
        require(success, "Transaction Unsuccessful");
    }
}
