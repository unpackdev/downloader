// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// used for whitelist management
import "./AccessControl.sol";
// used for general settings management
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBCMembership.sol";

contract BCMembershipBroker_v1 is
    AccessControl,
    Ownable,
    ReentrancyGuard
{

    address public immutable nftContract;
    address public treasury;

    uint256 public maxMintableTokenId;
    uint256 public mintPrice;
    bool public mintIsActive;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");


    event MaxMintableTokenIdUpdate(address indexed _by, uint256 indexed _maxTokenId);

    event MintPriceUpdate(address indexed _by, uint256 indexed _amount);

    event MintFlagUpdate(address indexed _by, bool indexed _active);

    event TreasuryUpdate(address indexed _by, address indexed _treasury);


    constructor(
        address _owner,
        address _defaultAdmin,
        address _nftContract,
        address _treasury,
        uint256 _maxMintableTokenId
    ) {
        _transferOwnership(_owner); // set account responsible for general settings management
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin); // set account responsible for whitelist management

        nftContract = _nftContract;
        treasury = _treasury;
        maxMintableTokenId = _maxMintableTokenId;

        mintPrice = 0.5 ether; // initial mint price
        mintIsActive = true;

        emit MaxMintableTokenIdUpdate(msg.sender, _maxMintableTokenId);
        emit TreasuryUpdate(msg.sender, _treasury);
    }


    modifier canMint(address _to) {
        require(mintIsActive, "Minting is not active");
        require(msg.value == mintPrice, "Tx value needs to be equal to mint price");
        require(hasRole(WHITELISTED_ROLE, _to), "Receiver is not whitelisted");
        uint256 totalSupply = IBCMembership(nftContract).totalSupply();
        require(totalSupply + 1 <= maxMintableTokenId, "No tokens available for mint");
        _;
    }


    function mint()
        external
        payable
        canMint(msg.sender)
        nonReentrant
    {
        IBCMembership(nftContract).safeMint(msg.sender);
        _revokeRole(WHITELISTED_ROLE, msg.sender);
    }

    function mintTo(
        address _to
    )
        external
        payable
        onlyOwner
        canMint(_to)
        nonReentrant
    {
        IBCMembership(nftContract).safeMint(_to);
        _revokeRole(WHITELISTED_ROLE, _to);
    }

    function mintToWithUri(
        address _to,
        string memory _uri
    )
        external
        payable
        onlyOwner
        canMint(_to)
        nonReentrant
    {
        IBCMembership(nftContract).safeMint(_to, _uri);
        _revokeRole(WHITELISTED_ROLE, _to);
    }

    function setMaxMintableTokenId(
        uint256 _maxMintableTokenId
    )
        external
        onlyOwner
    {
        require(maxMintableTokenId > _maxMintableTokenId);
        maxMintableTokenId = _maxMintableTokenId;
        emit MaxMintableTokenIdUpdate(msg.sender, _maxMintableTokenId);
    }

    function setMintPrice(
        uint256 _mintPrice
    )
        external
        onlyOwner
    {
        mintPrice = _mintPrice;
        emit MintPriceUpdate(msg.sender, _mintPrice);
    }

    function setTreasury(
        address _treasury
    )
        external
        onlyOwner
    {
        treasury = _treasury;
        emit TreasuryUpdate(msg.sender, _treasury);
    }

    function withdrawTotalBalanceToTreasury()
        external
        onlyOwner
    {
       uint balance = address(this).balance;
       payable(treasury).transfer(balance);
    }

    function flipMintFlag()
        external
        onlyOwner
    {
        mintIsActive = !mintIsActive;
        emit MintFlagUpdate(msg.sender, mintIsActive);
    }

    function setBaseUri(
        string memory _baseUri
    )
        external
        onlyOwner
    {
        IBCMembership(nftContract).setBaseUri(_baseUri);
    }

    function migrateToNewBroker(
        address _newBrokerContract
    )
        external
        onlyOwner
    {
        IBCMembership(nftContract).transferOwnership(_newBrokerContract);
    }

}
