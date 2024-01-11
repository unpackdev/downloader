// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./DigitalCertLib.sol";

contract DigitalCert is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply {

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private idCounter = 0;

    /*
      id => DigitalCertificate
     */
    mapping(uint256 => DigitalCertLib.DigitalCertificate) idToDigitalCeritificate;

    event CreateDigitalCert(uint256 indexed id, address toAccount, uint256 amount, uint256 expire, uint256 price );

    event UpdateExpire(uint256 indexed id, uint256 expire);

    event UpdatePrice(uint256 indexed id, uint256 price);

    modifier isDigitalCertificateCreated(uint256 id) {
      require(id <= idCounter, "this cert id is not created");
      _;
    }

    constructor(address owner, address minter1, address minter2, string memory uri) ERC1155(uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _grantRole(MINTER_ROLE, minter1);
        _grantRole(MINTER_ROLE, minter2);
        _grantRole(URI_SETTER_ROLE, minter1);
        _grantRole(URI_SETTER_ROLE, minter2);
    }

    function setExpireDate(uint256 id, uint256 expire) external onlyRole(MINTER_ROLE) isDigitalCertificateCreated(id) {
      require(expire > block.timestamp, "expire date invalid");
       idToDigitalCeritificate[id].expire = expire;
       emit UpdateExpire(id, expire);
    }

    function getExpireDateById(uint256 id) external view returns(uint256) {
      return idToDigitalCeritificate[id].expire;
    }

    function setPrice(uint256 id, uint256 price) external onlyRole(MINTER_ROLE) isDigitalCertificateCreated(id) {
      require(price >= 0, "price should >= 0");
      idToDigitalCeritificate[id].price = price;
      emit UpdatePrice(id, price);
    }

    function getPriceById(uint256 id) external view returns(uint256) {
      return idToDigitalCeritificate[id].price;
    }

    function getDigitalCertificate(uint256 id, address marketAddress) external view returns(DigitalCertLib.DigitalCertificateRes memory) {
      DigitalCertLib.DigitalCertificate memory cert = idToDigitalCeritificate[id];
      DigitalCertLib.DigitalCertificateRes memory res = DigitalCertLib.DigitalCertificateRes({
        certId: id,
        expire: cert.expire,
        price: cert.price,
        available: balanceOf(marketAddress, id),
        isPaused: false
      });
      return res;
    }

    function getLastId() public view returns(uint256) {
      return idCounter;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function createDigitalCert(address account, uint256 amount,uint256 expire, uint256 price, bytes calldata data) public onlyRole(MINTER_ROLE) {
      idCounter += 1;
      uint256 newId = idCounter;
      idToDigitalCeritificate[newId] = DigitalCertLib.DigitalCertificate({
        expire: expire,
        price: price
      });
      _mint(account, newId, amount, data);
      emit CreateDigitalCert(newId, account, amount, expire, price);
    }

    function createDigitalCertBatch(address account, uint256[] calldata amounts, uint256[] calldata expires, uint256[] calldata prices, bytes calldata data) public onlyRole(MINTER_ROLE) {
      require(amounts.length == expires.length && amounts.length == prices.length, "data length is not eq");
      for(uint256 i = 0; i < amounts.length; i++) {
        createDigitalCert(account, amounts[i], expires[i], prices[i], data);
      }
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
        isDigitalCertificateCreated(id)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        for(uint256 i = 0; i < ids.length; i++) {
          require(ids[i] <= idCounter, "Id is not created yet");
        }
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}