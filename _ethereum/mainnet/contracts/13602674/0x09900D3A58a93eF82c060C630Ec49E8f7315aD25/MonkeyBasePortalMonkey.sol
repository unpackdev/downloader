pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkelValidator.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract MonkeyBasePortalMonkey is ERC721, MerkelValidator, Ownable {
    event MonkeyFed(uint256 id, uint256 level);
    address payable public constant monkeybaseaddress =
        0x50F909A9AA4ACf52e1c31f28cb455b3CA0e3e04D;
    address payable public constant feedbananaaddress =
        0xEca678138946013F3512fDBe16f6Aea88476a628;

    uint256 public constant maxlevel = 5;
    uint256 public constant totalItems = 1111;

    uint256 public constant mintPrice = 0.039 ether;
    uint256 public constant bananaPrice = 0.03 ether;

    bool private feedBannanaLock = true;
    bool private feedBannanaLevel5Lock = true;

    /**
     * @notice Constructor which primarily used to set the base url and setting all nft's for sale
     **/
    constructor() public ERC721("MonkeyBasePortalMonkey", "MBPM") {
        _setBaseURI("http://api.wemonkeybase.com/monkey/");
    }
    // level tracking mapping
    mapping(uint256 => uint256) public level;

    /**
     * @notice Mints the NFT
     * @param _id token id
     */
    function mintItem(uint256 _id) external payable {
        require(msg.value == mintPrice, "Not enough");
        require(_id < totalItems, "Invalid ID");

        level[_id] = 1;
        _mint(msg.sender, _id);

        (bool success, ) = monkeybaseaddress.call{value: msg.value}("");
        require(success, "Failed");
    }

    /**
     * @notice Upgrade monkey by paying for bannana
     * @param _id token id
     */
    function feedBannana(uint256 _id) external payable {
        require(!feedBannanaLock, "Feed Bannana locked");
        require(ownerOf(_id) == msg.sender, "Not Owner");
        require(msg.value == bananaPrice, "Not enough");
        require(_id < totalItems, "Invalid ID");
        require( level[_id] <  maxlevel, "Cannot upgrade further");
        if (level[_id] == 4) {
            require(!feedBannanaLevel5Lock, "Level 5 upgrade locked");
        }
        level[_id] = level[_id].add(uint(1));
        (bool success, ) = feedbananaaddress.call{value: msg.value}("");
        require(success, "Failed");
        emit MonkeyFed(_id, level[_id]);
    }

    /**
     * @notice Upgrade monkey by completing challenge without paying any fee
     * @param merkleProof Owners merkleProof generated with merkel root
     * @param _tokenId token id
     * @param _levelToUpgrade level to upgrade to
     */
    function levelUp(bytes32[] calldata merkleProof, uint256 _tokenId, uint256 _levelToUpgrade) external {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
        require(level[_tokenId] > 0, "Monkey is not minted");
        require(_levelToUpgrade != 0, "invalid level");
        require(_levelToUpgrade <= 5, "invalid level");
        if (_levelToUpgrade == 2) {
            require(level[_tokenId] == 1, "invalid previous level");
            verify(level2UpgradeMerkelRoot, _tokenId, merkleProof);
            level[_tokenId] = 2;
        } else if (_levelToUpgrade == 3) {
            require(level[_tokenId] == 2, "invalid previous level");
            verify(level3UpgradeMerkelRoot, _tokenId, merkleProof);
            level[_tokenId] = 3;
        } else if (_levelToUpgrade == 4) {
            require(level[_tokenId] == 3, "invalid previous level");
            verify(level4UpgradeMerkelRoot, _tokenId, merkleProof);
            level[_tokenId] = 4;
        } else if (_levelToUpgrade == 5) {
            require(level[_tokenId] == 4, "invalid previous level");
            verify(level5UpgradeMerkelRoot, _tokenId, merkleProof);
            level[_tokenId] = 5;
        }
    }

    /**
     * @notice Unlocks feeding bannana
    */
    function unlockFeedingBannana() external onlyOwner {
        feedBannanaLock = false;
    }

    /**
     * @notice Unlocks feeding bannana to level
    */
    function unlockLevel5UpgradeByFeedingBannana() external onlyOwner {
        feedBannanaLevel5Lock = false;
    }

    /**
     * @notice Set merkel root to upgrade to level 2
     * @param _level2UpgradeMerkelRoot merkel root
     */
    function setLevel2UpgradeMerkelRoot(bytes32 _level2UpgradeMerkelRoot) external onlyOwner {
        level2UpgradeMerkelRoot = _level2UpgradeMerkelRoot;
    }

    /**
     * @notice Set merkel root to upgrade to level 3
     * @param _level3UpgradeMerkelRoot merkel root
     */
    function setLevel3UpgradeMerkelRoot(bytes32 _level3UpgradeMerkelRoot) external onlyOwner {
        level3UpgradeMerkelRoot = _level3UpgradeMerkelRoot;
    }

    /**
     * @notice Set merkel root to upgrade to level 4
     * @param _level4UpgradeMerkelRoot merkel root
     */
    function setLevel4UpgradeMerkelRoot(bytes32 _level4UpgradeMerkelRoot) external onlyOwner {
        level4UpgradeMerkelRoot = _level4UpgradeMerkelRoot;
    }

    /**
     * @notice Set merkel root to upgrade to level 5
     * @param _level5UpgradeMerkelRoot merkel root
     */
    function setLevel5UpgradeMerkelRoot(bytes32 _level5UpgradeMerkelRoot) external onlyOwner {
        level5UpgradeMerkelRoot = _level5UpgradeMerkelRoot;
    }

    /**
     * @notice returns the tokenURI of the nft
     * @param _tokenId token id
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalItems, "Invalid ID");
        require(_tokenId >= 0, "Invalid ID");
        return strConcat(baseURI(), uintToStr(_tokenId));
    }

    /**
     * @notice returns the number of NFTs available for minting
     */
    function getAvailableMonkeys() public view returns (uint256) {
        uint256 available = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (level[i] == 0) {
                available++;
            }
        }
        return available;
    }

    struct Monkey {
        address owner;
        uint256 level;
        uint256 id;
    }

    /**
     * @notice returns the list of available monkeys for minting
     */
    function getMonkeysList(bool available) public view returns (Monkey[] memory) {
        uint256 totalCount = totalItems;
        if (available) {
            totalCount = getAvailableMonkeys();
        }
        uint256 counter = 0;
        Monkey[] memory result = new Monkey[](totalCount);
        for (uint256 i = 0; i < totalItems; i++) {
            if ((available && level[i] == 0) || !available) {
                address owner = address(0);
                if (_exists(i)) {
                    owner = ownerOf(i);
                }
                result[counter] = Monkey(owner, level[i], i);
                counter++;
            }
        }
        return result;
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory result)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        result = string(bstr);
    }
}
