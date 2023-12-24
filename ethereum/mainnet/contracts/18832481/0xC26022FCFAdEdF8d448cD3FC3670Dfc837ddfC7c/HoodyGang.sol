// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IHoody.sol";
import "./IHoodySign.sol";

interface IHoodyTraits {
    function useTraitsForUpdateNFT(uint16[] memory, uint16[] memory) external;
}

contract HoodyGang is ERC721Enumerable, IHoody, Ownable {
    enum WLTYPE {
        OG,
        BB,
        CWL,
        FCFS
    }

    enum PHASE {
        BEFORE,
        FIRST,
        SECOND,
        PUBLIC
    }

    address public hoodySign;
    address public hoodyTraits;
    address public hoodyMigrate;
    string public baseURI;

    uint256 public PUBLIC_PRICE = 0.03 ether;
    mapping(PHASE => mapping(WLTYPE => uint256[3])) public WL_PRICES;
    mapping(address => mapping(PHASE => mapping(WLTYPE => uint16)))
        public WL_AMOUNTS;

    uint256 public referReward;
    uint256 public constant MaxMintNumber = 6666;

    uint16 public batchNumber = 10;

    uint256 public newMintNumber;
    uint256 public migrateNumber = 6666;

    address public communityWallet = 0xfbEDD27832f02e2FfB4f52c03AF51e77D4f53DB3;

    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => bool) public isOG;
    mapping(address => bool) public isReferral;
    mapping(address => bool) public isNotFirstMint;

    mapping(PHASE => uint256) public phaseStartTime;

    mapping(WLTYPE => bytes32) public wlRoots;

    event SetHoody(uint256 tokenID, string tokenURI);
    event MigrateOG(
        address holder,
        uint256 tokenID,
        uint256 ogID,
        string tokenURI
    );

    modifier onlyMigrate() {
        require(
            msg.sender == hoodyMigrate,
            "Only HoodyMigrate can call this function."
        );
        _;
    }

    constructor(
        uint256 _referReward
    ) ERC721("Hoody Gang", "HG") Ownable(msg.sender) {
        referReward = _referReward;

        WL_PRICES[PHASE.FIRST][WLTYPE.OG][0] = 0.013 ether;
        WL_PRICES[PHASE.FIRST][WLTYPE.OG][1] = 0.01 ether;
        WL_PRICES[PHASE.FIRST][WLTYPE.BB][0] = 0.016 ether;
        WL_PRICES[PHASE.FIRST][WLTYPE.BB][1] = 0.013 ether;
        WL_PRICES[PHASE.FIRST][WLTYPE.CWL][0] = 0.019 ether;
        WL_PRICES[PHASE.FIRST][WLTYPE.CWL][1] = 0.016 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.OG][0] = 0.016 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.OG][1] = 0.013 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.BB][0] = 0.019 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.BB][1] = 0.016 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.CWL][0] = 0.022 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.CWL][1] = 0.019 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.FCFS][0] = 0.025 ether;
        WL_PRICES[PHASE.SECOND][WLTYPE.FCFS][0] = 0.022 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.OG][0] = 0.019 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.OG][1] = 0.016 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.OG][2] = 0.022 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.BB][0] = 0.022 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.BB][1] = 0.019 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.BB][2] = 0.025 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.CWL][0] = 0.025 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.CWL][1] = 0.022 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.CWL][2] = 0.028 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.FCFS][0] = 0.028 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.FCFS][1] = 0.025 ether;
        WL_PRICES[PHASE.PUBLIC][WLTYPE.FCFS][2] = 0.03 ether;
    }

    function wlMint(
        uint16 _amount,
        WLTYPE _wlType,
        bytes32[] memory _proof
    ) external payable {
        PHASE currentPhase = getCurrentPhase();
        require(currentPhase != PHASE.BEFORE, "Can't mint for now.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, wlRoots[_wlType], leaf),
            "Invalid Proof"
        );

        (uint16 availableAmount, uint256 price) = getAvailableWLAmountAndPrice(
            msg.sender,
            currentPhase,
            _wlType
        );
        require(_amount <= availableAmount, "Exceed available amounts.");

        require(msg.value == price * _amount, "Insufficient amount!");

        if (!isNotFirstMint[msg.sender]) isNotFirstMint[msg.sender] = true;

        WL_AMOUNTS[msg.sender][currentPhase][_wlType] += _amount;
        hoodyMint(msg.sender, uint8(_amount));
    }

    function getAvailableWLAmountAndPrice(
        address _holder,
        PHASE _currentPhase,
        WLTYPE _wlType
    ) public view returns (uint16, uint256) {
        uint16 currentAmount = WL_AMOUNTS[_holder][_currentPhase][_wlType];
        if (_currentPhase == PHASE.FIRST && _wlType == WLTYPE.FCFS)
            return (0, 0);

        if (currentAmount < batchNumber)
            return (
                batchNumber - currentAmount,
                WL_PRICES[_currentPhase][_wlType][0]
            );
        else if (currentAmount < 2 * batchNumber)
            return (
                2 * batchNumber - currentAmount,
                WL_PRICES[_currentPhase][_wlType][1]
            );
        else {
            if (_currentPhase == PHASE.PUBLIC)
                return (100, WL_PRICES[_currentPhase][_wlType][2]);
            else return (0, 0);
        }
    }

    function publicMint(address _refer, uint8 _amount) public payable {
        mint(msg.sender, _refer, _amount);
    }

    function crossMint(address _to, uint8 _amount) external payable {
        mint(_to, communityWallet, _amount);
    }

    function mint(address _to, address _refer, uint8 _amount) internal {
        require(
            block.timestamp > phaseStartTime[PHASE.PUBLIC],
            "Can't pubic mint for now!"
        );
        require(
            msg.value == PUBLIC_PRICE * _amount,
            "Not enough amount for mint!"
        );
        require(
            isReferral[_refer] || _refer == communityWallet,
            "Invalid referral address!"
        );

        if (!isNotFirstMint[_to]) {
            isNotFirstMint[_to] = true;
            payable(_refer).transfer(referReward * _amount);
        }

        hoodyMint(_to, _amount);
    }

    function treasureMint(
        address[] memory _wList,
        uint8[] memory _amounts
    ) external onlyOwner {
        require(_wList.length == _amounts.length, "Invalid Params Length!");
        for (uint i; i < _wList.length; i++) {
            hoodyMint(_wList[i], _amounts[i]);
        }
    }

    function hoodyMint(address _minter, uint8 _amount) private {
        require(
            newMintNumber + _amount <= MaxMintNumber,
            "Reach out max number!"
        );
        payable(owner()).transfer(address(this).balance);
        setReferral();

        for (uint i; i < _amount; i++) {
            newMintNumber += 1;
            _mint(_minter, newMintNumber);
            tokenURIs[newMintNumber] = string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    Strings.toString(newMintNumber),
                    ".json"
                )
            );

            emit SetHoody(newMintNumber, tokenURIs[newMintNumber]);
        }
    }

    function ogMigrate(uint256 _ogID, string memory _uri) external onlyMigrate {
        migrateNumber += 1;
        _mint(tx.origin, migrateNumber);
        tokenURIs[migrateNumber] = _uri;
        setReferral();
        if (!isNotFirstMint[tx.origin]) isNotFirstMint[tx.origin] = true;
        isOG[migrateNumber] = true;
        emit MigrateOG(tx.origin, migrateNumber, _ogID, _uri);
    }

    function updatePublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setReferral() internal {
        if (!isReferral[tx.origin]) isReferral[tx.origin] = true;
    }

    function buildingBlockFreeMint(uint8 _amount) external onlyMigrate {
        hoodyMint(tx.origin, _amount);
    }

    function getCurrentPhase() public view returns (PHASE) {
        if (block.timestamp < phaseStartTime[PHASE.FIRST]) return PHASE.BEFORE;
        else if (block.timestamp < phaseStartTime[PHASE.SECOND])
            return PHASE.FIRST;
        else if (block.timestamp < phaseStartTime[PHASE.PUBLIC])
            return PHASE.SECOND;
        else return PHASE.PUBLIC;
    }

    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        _approve(to, tokenId, tx.origin);
    }

    function updateNFT(
        uint256 _tokenId,
        string memory _uri,
        uint16[] memory _oldTraits,
        uint16[] memory _newTraits,
        bytes memory _signature
    ) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the token Owner!"
        );
        require(!isOG[_tokenId], "Can't update OG!");
        uint16[] memory traits = new uint16[](
            _oldTraits.length + _newTraits.length
        );
        uint8 index = 0;
        for (uint i = 0; i < _oldTraits.length; i++) {
            traits[index] = _oldTraits[i];
            index++;
        }

        for (uint i = 0; i < _newTraits.length; i++) {
            traits[index] = _newTraits[i];
            index++;
        }

        require(
            IHoodySign(hoodySign).verifyForTraits(
                msg.sender,
                string(abi.encodePacked(_uri, Strings.toString(_tokenId))),
                traits,
                _signature
            ),
            "Invalid Signature"
        );

        IHoodySign(hoodySign).increaseNonce(msg.sender);

        IHoodyTraits(hoodyTraits).useTraitsForUpdateNFT(_oldTraits, _newTraits);

        tokenURIs[_tokenId] = _uri;

        emit SetHoody(_tokenId, _uri);
    }

    function setWLRoot(WLTYPE _type, bytes32 _root) external onlyOwner {
        wlRoots[_type] = _root;
    }

    function setLaunchTime(uint256 _time) external onlyOwner {
        phaseStartTime[PHASE.FIRST] = _time;
        phaseStartTime[PHASE.SECOND] = _time + 2 hours;
        phaseStartTime[PHASE.PUBLIC] = _time + 4 hours;
    }

    function setHoodyMigrate(address _hoodyMigrate) external onlyOwner {
        hoodyMigrate = _hoodyMigrate;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setRewardValues(uint256 _referReward) external onlyOwner {
        referReward = _referReward;
    }

    function setHoodyTraits(address _hoodyTraits) external onlyOwner {
        hoodyTraits = _hoodyTraits;
    }

    function setHoodySign(address _hoodySign) external onlyOwner {
        hoodySign = _hoodySign;
    }

    function setCommunityWallet(address _community) external onlyOwner {
        communityWallet = _community;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenURIs[tokenId];
    }
}
