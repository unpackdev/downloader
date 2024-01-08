// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC721Tradable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract UniqCollections is ERC721Tradable {
    // ----- VARIABLES ----- //
    string public METADATA_PROVENANCE_HASH;
    uint256 public ROYALTY_FEE;
    string internal _token_uri;
    uint256 internal _tokenNum;
    mapping(address => bool) internal _isPrizeCollectedForAddress;
    address internal _claimingAddress;
    address internal _vestingAddress;
    address internal _vestingAddress2;

    // ----- MODIFIERS ----- //
    modifier notZeroAddress(address a) {
        require(a != address(0), "ZERO address can not be used");
        _;
    }

    // ----- EVENTS ----- //
    event MintedFromVesting(address _minter, uint256 _tokenId, uint256 _type);
    event MintedFromVesting2(address _minter, uint256 _tokenId, uint256 _type);

    event ReceivedRoyalties(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount
    );

    // ----- VIEWS ----- //
    function isPrizeCollectedForAddress(address _address)
        external
        view
        returns (bool)
    {
        return _isPrizeCollectedForAddress[_address];
    }

    function royaltyInfo(uint256)
        external
        view
        returns (address receiver, uint256 amount)
    {
        return (owner(), ROYALTY_FEE);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function baseTokenURI() public view override returns (string memory) {
        return _token_uri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://uniqly.com/api/nft-collections/";
    }

    // ----- PRIVATE METHODS ----- //
    constructor(
        address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol,
        string memory _ttokenUri,
        address _vestingAddr,
        address _vestingAddr2
    )
        notZeroAddress(_proxyRegistryAddress)
        ERC721Tradable(_name, _symbol, _proxyRegistryAddress)
    {
        ROYALTY_FEE = 750000; //7.5%
        _token_uri = _ttokenUri;
        _vestingAddress = _vestingAddr;
        _vestingAddress2 = _vestingAddr2;
    }

    // ----- PUBLIC METHODS ----- //
    function mintFromVesting() external {
        require(
            !_isPrizeCollectedForAddress[msg.sender],
            "Prize is already collected"
        );
        uint256 bonus = Vesting(_vestingAddress).bonus(msg.sender);
        uint256 bonus2 = Vesting(_vestingAddress2).bonus(msg.sender);
        require(bonus > 0 || bonus2 > 0, "Bonus not found");
        _isPrizeCollectedForAddress[msg.sender] = true;
        if (bonus > 0) {
            _safeMint(msg.sender, _tokenNum);
            emit MintedFromVesting(msg.sender, _tokenNum, bonus);
            _tokenNum++;
        }
        if (bonus2 > 0) {
            _safeMint(msg.sender, _tokenNum);
            emit MintedFromVesting2(msg.sender, _tokenNum, bonus2);
            _tokenNum++;
        }
    }

    function burn(uint256 _tokenId) external {
        if (msg.sender != _claimingAddress) {
            require(
                _isApprovedOrOwner(msg.sender, _tokenId),
                "Ownership or approval required"
            );
        }
        _burn(_tokenId);
    }

    function receivedRoyalties(
        address,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount
    ) external {
        emit ReceivedRoyalties(owner(), _buyer, _tokenId, _tokenPaid, _amount);
    }

    // ----- OWNERS METHODS ----- //
    function mintAsOwner(uint256 _tokenNumber, address _receiver)
        external
        onlyOwner
    {
        _safeMint(_receiver, _tokenNumber);
    }

    function batchMintAsOwner(
        uint256 _tokenNumber,
        uint256 _elements,
        address _receiver
    ) external onlyOwner {
        uint256 i = 0;
        for (i = 0; i < _elements; i++) {
            _safeMint(_receiver, _tokenNumber + i);
        }
    }

    function editRoyaltyFee(uint256 _newFee) external onlyOwner {
        ROYALTY_FEE = _newFee;
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function editTokenUri(string memory _ttokenUri) external onlyOwner {
        _token_uri = _ttokenUri;
    }

    function editClaimingAdress(address _newAddress) external onlyOwner {
        _claimingAddress = _newAddress;
    }

    function recoverERC20(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }
}

interface Ierc20 {
    function transfer(address, uint256) external;
}

interface Vesting {
    function bonus(address user) external view returns (uint256);
}
