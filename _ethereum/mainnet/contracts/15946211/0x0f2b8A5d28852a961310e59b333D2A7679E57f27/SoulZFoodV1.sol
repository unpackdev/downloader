// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Open Zeppelin libraries for controlling upgradability and access.
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface NFTContract is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);
}

contract SoulZFood is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    string public name;
    string public symbol;

    address public _pauserRole;
    address public _upgraderRole;

    NFTContract public SoulZNFT;
    mapping(uint256 => bool) public alreadyClaimedNftId;

    string private _baseURI;
    string private baseExtension;
    bool public revealedUri;

    // food mapped to id => supply
    mapping(uint256 => uint256) food;
    uint256 public MAX_SUPPLY;
    uint256 public SUPPLY_MINTED;
    uint256 public MAX_CLAIMS_PER_TX;

    event Claimed(uint256 tokenId, uint256 foodId, address claimer);

    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize(address soulZContract) public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC1155_init("");
        name = "SoulZFood";
        symbol = "SoulZFood";
        food[0] = 1555;
        food[1] = 1555;
        food[2] = 1555;
        food[3] = 1555;
        food[4] = 1557;
        MAX_SUPPLY = 7777;
        SUPPLY_MINTED = 0;
        MAX_CLAIMS_PER_TX = 10;
        baseExtension = ".json";
        _pauserRole = owner();
        _upgraderRole = owner();
        SoulZNFT = NFTContract(soulZContract);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyUpgrader {}

    modifier onlyPauser() {
        require(
            _msgSender() == _pauserRole,
            "Only Pauser Can Perform this action"
        );
        _;
    }
    modifier onlyUpgrader() {
        require(
            _msgSender() == _upgraderRole,
            "Only Upgrader Can Perform this action"
        );
        _;
    }

    function transferPauserRole(address newPauserAddress) public onlyPauser {
        _pauserRole = newPauserAddress;
    }

    function transferUpgraderRole(address newUpgraderAddress)
        public
        onlyUpgrader
    {
        _upgraderRole = newUpgraderAddress;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(revealedUri, "URI NOT REVEALED YET!");

        return
            bytes(_baseURI).length > 0
                ? string(
                    abi.encodePacked(_baseURI, id.toString(), baseExtension)
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    function getBaseUri() public view returns (string memory) {
        require(revealedUri, "URI not Revealed");
        return _baseURI;
    }

    function setBaseExtension(string memory newBaseExtension) public onlyOwner {
        baseExtension = newBaseExtension;
    }

    function setMaxClaimsPerTx(uint256 newLimit) public onlyOwner {
        MAX_CLAIMS_PER_TX = newLimit;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function revealURI() public onlyOwner {
        revealedUri = true;
    }

    function foodLeft(uint256 id) public view returns (uint256) {
        return food[id];
    }

    function getTokenIdsAlreadyClaimed(uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory tokenId = new uint256[](tokenIds.length);
        bool[] memory claimedStatus = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (alreadyClaimedNftId[tokenIds[i]] == true) {
                tokenId[i] = tokenIds[i];
                claimedStatus[i] = true;
            } else {
                tokenId[i] = tokenIds[i];
                claimedStatus[i] = false;
            }
        }

        return (tokenId, claimedStatus);
    }

    function randomGenerator(uint256 tokenId, uint256 iterator)
        internal
        view
        returns (uint256)
    {
        uint256 randNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.coinbase,
                    block.number,
                    _msgSender(),
                    tokenId,
                    iterator
                )
            )
        );
        randNumber = randNumber.mod(5);

        while (food[randNumber] == 0) {
            randNumber = randNumber.add(1).mod(5); // use the next id incase not available moding value to keep between range
        }

        return randNumber;
    }

    function updateSupply(uint256 id) internal {
        food[id] -= 1;
        SUPPLY_MINTED += 1;
    }

    function _claim(uint256 tokenId, uint256 iterator) internal {
        require(SUPPLY_MINTED <= MAX_SUPPLY, "No More Supply Left to Mint");
        require(!alreadyClaimedNftId[tokenId], "Token ID Already Claimed");
        require(
            SoulZNFT.ownerOf(tokenId) == _msgSender(),
            "Cannot Claim For A Token Id you do not own"
        );
        uint256 idToMint = randomGenerator(tokenId, iterator);
        alreadyClaimedNftId[tokenId] = true;
        updateSupply(idToMint);
        _mint(_msgSender(), idToMint, 1, "");
        emit Claimed(tokenId, idToMint, _msgSender());
    }

    function claim(uint256[] memory tokenIds) public nonReentrant {
        require(
            tokenIds.length <= MAX_CLAIMS_PER_TX,
            "NOT ALLOWED: MAX_CLAIMS_PER_TX exceeded for Tokens Ids to be processed in a single tx"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claim(tokenIds[i], i);
        }
    }
}
