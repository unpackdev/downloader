// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Math.sol";

interface IN is IERC721 {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}

interface IPunk {
    function balanceOf(address wallet) external view returns (uint256);
}

interface IERC721Farm {
    function depositsOf(address account) external view returns (uint256[] memory);
}

/*
    https://twitter.com/_n_collective

    Pythagoras said that The Universal Creator had formed two things in His own image: the first was the cosmic system
    with its myriads of suns, moons, and planets; the second was Man, in whose nature the entire universe existed in miniature.
    ... that Man will resurrect once the clock embraces the cold.
    Caution! To witness him resurrect, a Weapon must be given in due sacrifice once the cold arrives.

    Men lured by desire, trust is no option. Trust must be minimized for the alternate reality to arrive — the metaverse.
    The Weapons are of great significance, for that a mission of this scale does not come without opposition.
    The Collective must be determined to protect the idea of a trustless alternate existence over generations to come, silently.

    The faceless. We became self-aware only to realize that this story is not about us. The Collective understands this story is not about us.
    The Collective always prevails.

    Let us cheer the Collective contributors — below with their Discord names — holding up high our values,
    our beliefs, with rigorous loyalty; engrave them on what is the fundament of the trustless reality to come — the Ethereum blockchain.
    These are snippets from the Collective Discord, #philosophy channel (https://discord.gg/pfhtnhPsPB):

    browntaneer on the origin story of the Collective:
    "Before the Collective, there was One.

    One made no friends, held no lovers, had no names.
    All too aware of the limitations imposed by one's mortality, One worked to change all that they could.
    But a life fought hard, and lived well can only take one so far.

    A lifetime could be spent in making a castle but, if sculpted with sand, the waves of time will wash it all away.

    How does One endure when a single lifetime isn't enough.
    Who could One trust?
    How can One shed the baggage of one’s name and birth?
    How can we hide what we were given, so that we may show what we choose to be?"

    Kummatti:
    "our Masks hide who we are expected to be. and reveal who we truly are. the Collective."

    Redrobot:
    "We wear the mask that grins and lies,
    It hides our cheeks and shades our eyes,—
    This debt we pay to human guile;
    With torn and bleeding hearts we smile,
    And mouth with myriad subtleties.

    Why should the world be over-wise,
    In counting all our tears and sighs?
    Nay, let them only see us, while
    We wear the Mask.

    We smile, but, O great Christ, our cries
    To thee from tortured souls arise.
    We sing, but oh the clay is vile
    Beneath our feet, and long the mile;
    But let the world dream otherwise,
    We wear the Mask!"

    Kummatti:
    "some say the Mask is to hide the truth.
    but what do they know?
    truth can’t be hidden.
    truth can’t be veiled.
    truth can’t be masked.
    truth is.
    the Mask is."
    truth can’t be hidden.
    they’re just unwilling to see the Collective.

    Nietzsche:
    "In a crowd, faces disappear"

    Kummatti:
    "Don't aspire to be what others want you to be
    Aspire to be all that you can be
    The rest will follow"

    This is the Collective. Welcome.
*/
contract PythagoreanWeapons is ERC721, Ownable, ReentrancyGuard, ERC721Holder {
    IN public constant n = IN(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6);
    IPunk public constant punk = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IERC721 public constant bayc = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721 public constant mask = IERC721(0x6327f6305331f7E0CCFcaC2bCA4a4a8B87afDa32);
    IERC721Farm public constant treasure = IERC721Farm(0x08543f4c79f7e5d585A2622cA485e8201eFd9aDA);

    string[29] public ADJECTIVES = ["Glowing", "Savage", "Forgotten", "Flaming", "Stormy", "Fierce", "Corrupted", "Blazing", "Bleeding", "Dark", "Ancient", "Divine", "Cursed", "Chaotic", "Titanic", "Mortal", "Blessed", "Vicious", "Numeric", "Devil", "Demonic", "Holy", "Mighty", "Cold", "Sinister", "Lunar", "Hardened", "Reaping", "Ravenous"];
    string[29] public NOUNS = ["Wind", "Night", "Moon", "Iron", "Dawn", "Sky", "Soul", "Breath", "Scream", "Oath", "Edge", "Winter", "Silver", "Ice", "Justice", "Fate", "Star", "Strike", "Pride", "Rage", "Sacrifice", "Shadow", "Victory", "War", "Truth", "Moonlight", "Thunder", "Steel", "Torrent"];
    string[29] public PLACES = ["Ellora", "Xi'an", "Alexandria", "Pythagore", "Teotihuacan", "Nineveh", "Angkor Wat", "Varanasi", "Carthage", "Ephesus", "Cusco", "Crotone", "Samos", "Luna", "Moghul", "Shartadar", "Muramar", "Stonefort", "Ambar City", "Fulghot", "Ramberseit", "Thambert", "Annon Tul", "Gondol", "Novastarius", "Centhuron", "Numbers Citadel", "Kartaros", "Silverthrone"];
    string[9] public PARTS = ["Body", "Blood Mark", "Button", "Handle", "Quillon", "Pommel", "Ornament", "Pythagor's Mark", "Tilt"];
    // 0-4 Swords, 5-9 Axe
    string[15] public WEAPONS = ["Sword", "Greatsword", "Broadsword", "Longsword", "Shortsword", "Hunteraxe", "Axe", "Blackaxe", "Greataxe", "Vikingaxe", "Hammer", "Warhammer", "Broadhammer", "Club", "Mace"];
    string public WEAPON_DESCRIPTION = "The Pythagorean school of thought teaches us that numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those. Numbers are all around us, have always been, will always be. Welcome to the Collective.";

    uint256 public constant RESERVED_N_TOKENS_TO_MINT = 700;
    uint256 public constant RESERVED_BAYC_TOKENS_TO_MINT = 444;
    uint256 public constant RESERVED_PUNK_TOKENS_TO_MINT = 177;
    uint256 public constant RESERVED_MASK_TOKENS_TO_MINT = 1500;
    uint256 public constant RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT = 879;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_FEE = 0.08 ether;
    uint256 public constant MINTABLE_TOKENS_PER_PUNK_TOKEN = 5;
    uint256 public constant MINTABLE_TOKENS_PER_BAYC_TOKEN = 2;
    uint256 public constant MAX_MINTS_PER_N_HOLDER = 3;
    uint256 public constant MAX_MINTS_PER_MASK_HOLDER = 2;
    uint256 public constant MAX_MINTS_PER_HOLDER = 20;
    uint256 public constant N_BASE_TOKEN_ID = 7302015;

    mapping(uint256 => bool) public nTokensMinted;
    mapping(uint256 => bool) public maskTokensMinted;
    mapping(address => uint256) public punkHoldersMintedByAddress;
    mapping(address => uint256) public baycHoldersMintedByAddress;
    mapping(address => uint256) public maskHoldersMintedByAddress;
    mapping(address => uint256) public nHoldersMintedByAddress;
    mapping(address => uint256) public openToAllHoldersMintedByAddress;
    uint256 public totalNHoldersMinted;
    uint256 public totalMaskHoldersMinted;
    uint256 public totalBAYCHoldersMinted;
    uint256 public totalPunkHoldersMinted;
    uint256 public totalEcosystemAndTeamMinted;
    uint256 public totalSupply;
    uint256 public totalTeamMinted;

    bool private _overrideTradingPreventionInMintingPeriod;
    bool private _finishInitialization;
    address public resurrectionContract;
    uint256 public endMintingPeriodDateAndTime;
    uint256 public endReservedSpotsMintingPeriodDateAndTime;
    uint256 public nextVestingPeriodDataAndTime;

    string[15] public firstAssets;
    string[15] public secondAssets;
    string[15] public thirdAssets;
    string[15] public fourthAssets;
    string[15] public fifthAssets;
    string[15] public sixthAssets;
    string[15] public seventhAssets;
    string public svgStyle;
    string public secondOrnament;
    string public topOrnament;
    string public bottomOrnament;

    // -------- MODIFIERS (CONVERTED TO FUNCTIONS TO REDUCE CONTRACT SIZE) --------

    function _onlyWhenInit() internal view {
        require(!_finishInitialization, "Wut?");
    }

    function _onlyWhenFinishInit() internal view {
        require(_finishInitialization, "Can't call this yet");
    }

    function _amountBiggerThanZero(uint256 amountToMint) internal pure {
        require(amountToMint > 0, "Amount need ot be bigger than 0");
    }

    function _sameAmountAndTokenLength(uint256 amountToMint, uint256[] memory tokenIds) internal pure {
        require(amountToMint == tokenIds.length, "Lengths mismatch");
    }

    function _includesMintFee(uint256 amountToMint) internal view {
        require(msg.value >= MINT_FEE * amountToMint, "Mint cost 0.08 eth per token");
    }

    function _includesMintFeeWith50PercentageDiscount(uint256 amountToMint) internal view {
        require(msg.value >= (MINT_FEE / 2) * amountToMint, "Mint cost 0.04 eth per token");
    }

    function _onlyInMintingPeriod() internal view {
        require(isInMintingPeriod(), "Not in minting period");
    }

    function _onlyInReservedMintingPeriod() internal view {
        require(isInReservedMintingPeriod(), "Reserved minting period is over");
    }

    function _canSacrifice() internal view {
        require(resurrectionContract == msg.sender, "You can't do that");
    }

    constructor(uint256 _endMintingPeriodDateAndTime, uint256 _endReservedSpotsMintingPeriodDateAndTime)
    ERC721("Pythagorean Weapons", "PythagoreanWeapons")
    {
        endMintingPeriodDateAndTime = _endMintingPeriodDateAndTime;
        endReservedSpotsMintingPeriodDateAndTime = _endReservedSpotsMintingPeriodDateAndTime;
        nextVestingPeriodDataAndTime = block.timestamp + (30 * 24 * 60 * 60);
    }

    function setFirstAssets(string[] memory first, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < first.length; i++) {
            firstAssets[i + start] = first[i];
        }
    }

    function setSecondAssets(string[] memory second, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < second.length; i++) {
            secondAssets[i + start] = second[i];
        }
    }

    function setThirdAssets(string[15] memory third) public onlyOwner {
        _onlyWhenInit();
        thirdAssets = third;
    }

    function setFourthAssets(string[15] memory fourth) public onlyOwner {
        _onlyWhenInit();
        fourthAssets = fourth;
    }

    function setFifthAssets(string[] memory fifth, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < fifth.length; i++) {
            fifthAssets[i + start] = fifth[i];
        }
    }

    function setSixthAssets(string[] memory sixth, uint256 start) public onlyOwner {
        _onlyWhenInit();
        for (uint256 i; i < sixth.length; i++) {
            sixthAssets[i + start] = sixth[i];
        }
    }

    function setSeventhAssets(string[15] memory seventh) public onlyOwner {
        _onlyWhenInit();
        seventhAssets = seventh;
    }

    function setSVGItems(
        string memory _svgStyle,
        string memory _secondOrnament,
        string memory _topOrnament,
        string memory _bottomOrnament
    ) public onlyOwner {
        _onlyWhenInit();
        svgStyle = _svgStyle;
        secondOrnament = _secondOrnament;
        topOrnament = _topOrnament;
        bottomOrnament = _bottomOrnament;
    }

    function finishInitialization(address newOwner) public onlyOwner {
        _onlyWhenInit();
        _finishInitialization = true;
        if (newOwner != owner()) {
            transferOwnership(newOwner);
        }
    }

    function claimVestedTeamTokens(uint256[] memory tokenIds) public onlyOwner {
        _onlyWhenFinishInit();
        require(block.timestamp > nextVestingPeriodDataAndTime, "Can't claim yet");
        // Vesting period every 1 month
        nextVestingPeriodDataAndTime = nextVestingPeriodDataAndTime + (30 * 24 * 60 * 60);
        for (uint256 i; i < tokenIds.length && i < 88; i++) {
            _safeTransfer(address(this), owner(), tokenIds[i], "");
        }
    }

    function mintTokenReservedForN(uint256 amountToMint, uint256[] memory tokenIds)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _sameAmountAndTokenLength(amountToMint, tokenIds);
        _includesMintFeeWith50PercentageDiscount(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted, "Can't mint anymore");
        require(MAX_MINTS_PER_N_HOLDER > nHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256[] memory treasureDepositedTokens = treasure.depositsOf(msg.sender);
        uint256 i;
        for (;
            i < tokenIds.length &&
            MAX_MINTS_PER_N_HOLDER > nHoldersMintedByAddress[msg.sender] &&
            RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted;
            i++) {
            uint256 tokenId = tokenIds[i];
            require(!nTokensMinted[tokenId], "Token was already been used");
            require(_isNHolder(tokenId, treasureDepositedTokens), "Not the token owner");
            totalNHoldersMinted++;
            nTokensMinted[tokenId] = true;
            nHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * (MINT_FEE / 2);
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForMask(uint256 amountToMint, uint256[] memory tokenIds)
    public
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _sameAmountAndTokenLength(amountToMint, tokenIds);
        _onlyInReservedMintingPeriod();
        require(RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted, "Can't mint anymore");
        require(MAX_MINTS_PER_MASK_HOLDER > maskHoldersMintedByAddress[msg.sender], "Insufficient balance");
        for (
            uint256 i;
            i < tokenIds.length &&
            MAX_MINTS_PER_MASK_HOLDER > maskHoldersMintedByAddress[msg.sender] &&
            RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted;
            i++
        ) {
            uint256 tokenId = tokenIds[i];
            require(!maskTokensMinted[tokenId], "Token was already been used");
            require(mask.ownerOf(tokenId) == msg.sender, "Not the token owner");
            totalMaskHoldersMinted++;
            maskTokensMinted[tokenId] = true;
            maskHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
    }

    function mintTokenReservedForPunkHolders(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted, "Can't mint anymore");
        uint256 balance = punk.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_PUNK_TOKEN;
        require(balance > punkHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        // Since i can be lower than amountToMint after loop ends
        for (
        ;
            i < amountToMint &&
            RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted &&
            balance > punkHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalPunkHoldersMinted++;
            punkHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForBAYCHolders(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInReservedMintingPeriod();
        require(RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted, "Can't mint anymore");
        uint256 balance = bayc.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_BAYC_TOKEN;
        require(balance > baycHoldersMintedByAddress[msg.sender], "Insufficient balance");
        // Since i can be lower than amountToMint after loop ends
        uint256 i;
        for (
        ;
            i < amountToMint &&
            RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted &&
            balance > baycHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalBAYCHoldersMinted++;
            baycHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintToken(uint256 amountToMint)
    public
    payable
    nonReentrant
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _includesMintFee(amountToMint);
        _onlyInMintingPeriod();
        require(
            MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalSupply - totalEcosystemAndTeamMinted,
            "Can't mint anymore"
        );
        require(MAX_MINTS_PER_HOLDER > openToAllHoldersMintedByAddress[msg.sender], "Insufficient balance");
        // Since i can be lower than amountToMint after loop ends
        uint256 i;
        for (
        ;
            i < amountToMint &&
            MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalSupply - totalEcosystemAndTeamMinted &&
            MAX_MINTS_PER_HOLDER > openToAllHoldersMintedByAddress[msg.sender];
            i++
        ) {
            openToAllHoldersMintedByAddress[msg.sender]++;
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * MINT_FEE;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForEcosystemAndTeam(uint256 amountToMint)
    public
    nonReentrant
    onlyOwner
    {
        _onlyWhenFinishInit();
        _amountBiggerThanZero(amountToMint);
        _onlyInMintingPeriod();
        require(RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalTeamMinted, "Can't mint anymore");
        for (uint256 i; i < amountToMint && RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT > totalTeamMinted; i++) {
            totalTeamMinted++;
            // Only 10% now, rest go to contract for vesting
            _mintNextToken(totalTeamMinted > 87 ? address(this) : msg.sender);
        }
    }

    function isInMintingPeriod() public view returns (bool) {
        return
        endMintingPeriodDateAndTime > block.timestamp && MAX_SUPPLY > totalSupply;
    }

    function isInReservedMintingPeriod() public view returns (bool) {
        return
        endReservedSpotsMintingPeriodDateAndTime > block.timestamp &&
        (RESERVED_N_TOKENS_TO_MINT > totalNHoldersMinted ||
        RESERVED_BAYC_TOKENS_TO_MINT > totalBAYCHoldersMinted ||
        RESERVED_PUNK_TOKENS_TO_MINT > totalPunkHoldersMinted ||
        RESERVED_MASK_TOKENS_TO_MINT > totalMaskHoldersMinted);
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return n.getFirst(tokenId + N_BASE_TOKEN_ID);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return n.getSecond(tokenId + N_BASE_TOKEN_ID);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return n.getThird(tokenId + N_BASE_TOKEN_ID);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return n.getFourth(tokenId + N_BASE_TOKEN_ID);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return n.getFifth(tokenId + N_BASE_TOKEN_ID);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return n.getSixth(tokenId + N_BASE_TOKEN_ID);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return n.getSeventh(tokenId + N_BASE_TOKEN_ID);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return n.getEight(tokenId + N_BASE_TOKEN_ID);
    }

    function setOverrideTradingPreventionInMintingPeriod(bool overrideTradingPreventionInMintingPeriod) external onlyOwner {
        _overrideTradingPreventionInMintingPeriod = overrideTradingPreventionInMintingPeriod;
    }

    function setResurrectionContract(address _resurrectionContract) external onlyOwner {
        resurrectionContract = _resurrectionContract;
    }

    function sacrifice(uint256 tokenId) external {
        _canSacrifice();
        _burn(tokenId);
    }

    function spotsForAll() external view returns (uint256) {
        uint256 balance = MAX_SUPPLY - RESERVED_ECOSYSTEM_TEAM_TOKENS_TO_MINT;
        if (balance > totalSupply - totalTeamMinted) {
            return balance - (totalSupply - totalTeamMinted);
        } else {
            return 0;
        }
    }

    function spotsForMask() external view returns (uint256) {
        uint256 balance = mask.balanceOf(msg.sender);
        if (balance > maskHoldersMintedByAddress[msg.sender]) {
            return Math.min(balance, MAX_MINTS_PER_MASK_HOLDER) - maskHoldersMintedByAddress[msg.sender];
        } else {
            return 0;
        }
    }

    function spotsForN() external view returns (uint256) {
        uint256 balance = n.balanceOf(msg.sender) + treasure.depositsOf(msg.sender).length;
        if (balance > nHoldersMintedByAddress[msg.sender]) {
            return Math.min(balance, MAX_MINTS_PER_N_HOLDER) - nHoldersMintedByAddress[msg.sender];
        } else {
            return 0;
        }
    }

    function spotsForBAYC() external view returns (uint256) {
        uint256 balance = bayc.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_BAYC_TOKEN;
        if (balance > baycHoldersMintedByAddress[msg.sender]) {
            return balance - baycHoldersMintedByAddress[msg.sender];
        }
        return 0;
    }

    function spotsForPunk() external view returns (uint256) {
        uint256 balance = punk.balanceOf(msg.sender) * MINTABLE_TOKENS_PER_PUNK_TOKEN;
        if (balance > punkHoldersMintedByAddress[msg.sender]) {
            return balance - punkHoldersMintedByAddress[msg.sender];
        }
        return 0;
    }

    // -------- JSON & SVG --------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth, uint256 sixth,
        uint256 seventh, uint256 eight, uint256 angle) = _getNumbersOfToken(tokenId);
        string memory svgOutput = _svg(first, second, third, fourth, fifth, sixth, seventh, eight, angle);

        string memory json = Base64._encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _generateWeaponName(tokenId, second + third, fourth + fifth, first, sixth + seventh),
                        '", "description": "',
                        WEAPON_DESCRIPTION,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64._encode(bytes(svgOutput)),
                        '", "attributes": [',
                        _generateAttributes(first, second, third, fourth, fifth, sixth, seventh, eight, angle),
                        ']}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));

        return json;
    }

    // For when the resurrection comes, the weapon comes too
    function svgOfToken(uint256 tokenId) external view returns (string memory svgOutput) {
        (uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth, uint256 sixth,
        uint256 seventh, uint256 eight, uint256 angle) = _getNumbersOfToken(tokenId);
        svgOutput = _svg(first, second, third, fourth, fifth, sixth, seventh, eight, angle);
    }

    // -------- INTERNALS --------

    function _mintNextToken(address to) internal {
        _safeMint(to, totalSupply);
        totalSupply++;
    }

    function _isNHolder(uint256 tokenId, uint256[] memory treasureDepositedTokens) internal view returns (bool) {
        if (n.ownerOf(tokenId) == msg.sender) {
            return true;
        } else {
            for (uint256 i; i < treasureDepositedTokens.length; i++) {
                if (tokenId == treasureDepositedTokens[i]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (from != address(0)) {
            // If no mint
            require(!isInMintingPeriod() || _overrideTradingPreventionInMintingPeriod, "Still in minting period");
        }
    }

    // -------- INTERNALS JSON & SVG --------

    function _generateWeaponName(uint256 tokenId, uint256 adjective, uint256 noun, uint256 weapon, uint256 place) internal view returns (string memory name) {
        // “1234 - Glowing-Wind Sword of Ellora"
        name = string(
            abi.encodePacked(
                _toString(tokenId),
                " - ",
                ADJECTIVES[adjective],
                "-",
                NOUNS[noun],
                " ",
                WEAPONS[weapon],
                " of ",
                PLACES[place]
            )
        );
    }

    // To prevent stack too deep
    struct Vars {
        uint256 first;
        uint256 second;
        uint256 third;
        uint256 fourth;
        uint256 fifth;
        uint256 sixth;
        uint256 seventh;
        uint256 eight;
        uint256 sum;
        uint256 angle;
    }

    function _getNumbersOfToken(uint256 tokenId)
    internal
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        Vars memory vars;

        vars.first = getFirst(tokenId);
        vars.second = getSecond(tokenId);
        vars.third = getThird(tokenId);
        vars.fourth = getFourth(tokenId);
        vars.fifth = getFifth(tokenId);
        vars.sixth = getSixth(tokenId);
        vars.seventh = getSeventh(tokenId);
        vars.eight = getEight(tokenId);
        vars.sum = vars.first + vars.second + vars.third + vars.fourth + vars.fifth + vars.sixth + vars.seventh + vars.eight;
        uint256 angle = ((109090910 * vars.sum) - 2181818181) / 100000000;
        return (vars.first, vars.second, vars.third, vars.fourth, vars.fifth, vars.sixth, vars.seventh, vars.eight, angle);
    }

    function _generateAttributes(uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth,
        uint256 sixth, uint256 seventh, uint256 eight, uint256 angle) internal view returns (string memory attributesOutput) {

        attributesOutput = string(
            abi.encodePacked(
                _generateAttribute(PARTS[0], first),
                ",",
                _generateAttribute(PARTS[1], second),
                ",",
                _generateAttribute(PARTS[2], third),
                ",",
                _generateAttribute(PARTS[3], fourth),
                ",",
                _generateAttribute(PARTS[4], fifth),
                ",",
                _generateAttribute(PARTS[5], sixth),
                ",",
                _generateAttribute(PARTS[6], seventh),
                ",",
                _generateAttribute(PARTS[7], eight),
                ",",
                _generateAttribute(PARTS[8], angle)
            )
        );
    }

    function _generateAttribute(string memory traitType, uint256 number) internal pure returns (string memory attributeOutput) {
        attributeOutput = string(
            abi.encodePacked(
                '{"trait_type": "',
                traitType,
                '","value": "',
                _toString(number),
                '"}'
            )
        );
    }

    function _svg(uint256 first, uint256 second, uint256 third, uint256 fourth, uint256 fifth,
        uint256 sixth, uint256 seventh, uint256 eight, uint256 angle) internal view returns (string memory svgOutput) {

        string[4] memory weaponParts;

        weaponParts[0] = _surroundWithId(
            "flipWeaponsParts",
            string(
                abi.encodePacked(
                    firstAssets[first],
                    thirdAssets[third],
                    fourthAssets[fourth],
                    fifthAssets[fifth],
                    sixthAssets[sixth],
                    _surroundWithId("ORNAMENT", seventhAssets[seventh])
                )
            )
        );
        weaponParts[1] = _flipHorizontally("flipWeaponsParts", "1080");
        weaponParts[2] = _buildAdditionalOrnaments(eight);
        weaponParts[3] = secondAssets[second];

        string[4] memory svgParts;

        svgParts[0] = _svgHeader('viewBox="0 0 1080 1080"');
        svgParts[1] = svgStyle;
        svgParts[2] = _transform(
            string(abi.encodePacked("rotate(", _svgAngle(angle), ",540,540)")),
            string(abi.encodePacked(weaponParts[0], weaponParts[1], weaponParts[2], weaponParts[3]))
        );
        svgParts[3] = "</svg>";

        svgOutput = string(abi.encodePacked(svgParts[0], svgParts[1], svgParts[2], svgParts[3]));
    }

    function _buildAdditionalOrnaments(uint256 number) internal view returns (string memory) {
        // Ornament nothing (8), second (9,13), top (7,11), bottom (6,12), ALL (0, 14), second + top (1,2), second + bottom (3,4), bottom + top (5,10)
        if (number == 9 || number == 13) {
            return secondOrnament;
        } else if (number == 7 || number == 11) {
            return topOrnament;
        } else if (number == 6 || number == 12) {
            return bottomOrnament;
        } else if (number == 0 || number == 14) {
            return string(abi.encodePacked(secondOrnament, topOrnament, bottomOrnament));
        } else if (number == 1 || number == 2) {
            return string(abi.encodePacked(secondOrnament, topOrnament));
        } else if (number == 3 || number == 4) {
            return string(abi.encodePacked(secondOrnament, bottomOrnament));
        } else if (number == 5 || number == 10) {
            return string(abi.encodePacked(bottomOrnament, topOrnament));
        }

        return "";
    }

    function _svgHeader(string memory attributes) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
                attributes,
                '>'
            )
        );
    }

    function _surroundWithId(string memory id, string memory input) internal pure returns (string memory output) {
        output = string(abi.encodePacked('<g id="', id, '">', input, "</g>"));
    }

    function _flipHorizontally(string memory id, string memory x) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                '<use xlink:href="#',
                id,
                '" href="#',
                id,
                '" transform="scale(-1 1) translate(-',
                x,
                ',0)"/>'
            )
        );
    }

    function _transform(string memory transformAttribute, string memory innerBody) internal pure returns (string memory output) {
        output = string(abi.encodePacked('<g transform="', transformAttribute, '">', innerBody, "</g>"));
    }

    function _svgAngle(uint256 angle) internal pure returns (string memory output) {
        if (angle == 30) {
            return "0";
        } else if (angle > 30) {
            return _toString(angle - 30);
        } else {
            return string(abi.encodePacked("-", _toString(30 - angle)));
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function _encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}