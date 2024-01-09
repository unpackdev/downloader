// SPDX-License-Identifier: UNLICENSED

/***********************************************************/
/** Contract created by CRCLS Networks, Inc
/** Author: MattXYZ @mattxyzeth mattxyz.eth
/** Author: KarlXYZ @karlxyzeth karlxyz.eth
/***********************************************************/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC2981Royalties.sol";

contract WerdWorldNFT is ERC721, ERC2981Royalties, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bool public isPreSaleActive;
    bool public isPublicSaleActive;
    bool public isSoldOut;
    bool public isRevealed;
    uint256 public maxSupply = 1002;

    uint8 private constant MAX_PUBLIC_MINT = 10;
    uint256 private constant PRICE_PER_TOKEN = 0.08 ether;
    uint8 private constant ROYALTY_CUT = 250;
    string private constant META_SUFFIX = ".json";
    string private _prerevealURI;
    string private _baseTokenURI;

    address private _contractOwner;
    mapping(address => bool) private _whitelist;
    mapping(address => uint16) private _mintCount;
    mapping(bytes32 => address[]) private _adminList;

    event SaleStatus();
    event Purchase();

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Denied");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, AccessControl, ERC2981Base)
      returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor(string memory baseUri, string memory prerevealURI) ERC721 ("TheWerdWorld", "WERD") {
        _contractOwner = msg.sender;
        // Set owner role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Set admin role
        _grantRole(ADMIN_ROLE, msg.sender);
        _adminList[ADMIN_ROLE].push(msg.sender);
        // Set the royalty cut
        _setRoyalties(msg.sender, ROYALTY_CUT);
        // Set the baseUri for the tokenURI method
        _baseTokenURI = baseUri;
        // Set the prerevealUri for the tokenURI method
        _prerevealURI = prerevealURI;
    }

    function setOwner(address newOwner) external onlyOwner {
        _contractOwner = newOwner;
        // Set owner role
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        // Set admin role
        _grantRole(ADMIN_ROLE, newOwner);
        // Revoke the previous owner
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Set the royalty cut
        _setRoyalties(newOwner, ROYALTY_CUT);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(_contractOwner).transfer(balance);
    }

    function mint(uint8 _amount) external payable {
        require(totalSupply() < maxSupply, "SOLD OUT!");
        require(_amount <= MAX_PUBLIC_MINT, "Requested too many");
        require(totalSupply() + _amount <= maxSupply, string(abi.encodePacked("Only ", (maxSupply - totalSupply()).toString(), " left.")));
        require(msg.value >= _amount * PRICE_PER_TOKEN, "Not enough ether");

        if (isPreSaleActive) {
            // Make sure the sender in on the whitelist.
            require(_whitelist[msg.sender], "Not on the whitelist");
        } else if (isPublicSaleActive) {
            // Make sure the sender isn't requesting too many
            require(_mintCount[msg.sender] + _amount <= MAX_PUBLIC_MINT, "Max amount exceeded");
        } else {
            revert("Sale not active");
        }

        // Set state first
        _mintCount[msg.sender] += _amount;

        // Mint functionality
        for (uint8 i; i < _amount; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }

        emit Purchase();

        if (totalSupply() == maxSupply) {
            isSoldOut = true;
            emit SaleStatus();
        }
    }

    function giftMint(address to) external onlyOwner {
        require(_tokenIds.current() + 1 <= maxSupply, "None left");
        _tokenIds.increment();
        _safeMint(to, _tokenIds.current());
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function totalForAccount() public view returns (uint16) {
        return _mintCount[msg.sender];
    }

    function getRole() public view onlyRole(ADMIN_ROLE) returns (string memory) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
          ? "owner"
          : "admin";
    }

    function togglePreSale() public onlyRole(ADMIN_ROLE) {
        if (isPreSaleActive) {
            isPreSaleActive = false;
        } else {
            isPreSaleActive = true;
        }

        emit SaleStatus();
    }

    function togglePublicSale() public onlyRole(ADMIN_ROLE) {
        if (isPublicSaleActive) {
            isPublicSaleActive = false;
        } else {
            isPreSaleActive = false;
            isPublicSaleActive = true;
        }

        emit SaleStatus();
    }

    function reveal() public onlyRole(ADMIN_ROLE) {
        isRevealed = true;
    }

    function updateWhitelist(address[] calldata _addresses) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = true;
        }
    }

    function isOnWhitelist(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function setAdmins(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            grantRole(ADMIN_ROLE, _addresses[i]);
            _adminList[ADMIN_ROLE].push(_addresses[i]);
        }
    }

    function revokeAdmins(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            revokeRole(ADMIN_ROLE, _addresses[i]);

            for(uint256 j;j < _adminList[ADMIN_ROLE].length;j++) {
                if (_adminList[ADMIN_ROLE][j] == _addresses[i]) {
                    _adminList[ADMIN_ROLE][j] = _adminList[ADMIN_ROLE][_adminList[ADMIN_ROLE].length-1];
                    _adminList[ADMIN_ROLE].pop();
                }
            }
        }
    }

    function getAdmins() public view onlyRole(ADMIN_ROLE) returns (address[] memory) {
      return _adminList[ADMIN_ROLE];
    }

    function setMaxSupply(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        maxSupply = _amount;
    }

    function tokenURI(uint256 _tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      if (isRevealed == false) {
        return string(abi.encodePacked(_prerevealURI, "pre-reveal", META_SUFFIX));
      }

      return bytes(_baseTokenURI).length > 0
        ? string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), META_SUFFIX))
        : "";
    }

    function setBaseTokenURI(string memory _newURI) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
