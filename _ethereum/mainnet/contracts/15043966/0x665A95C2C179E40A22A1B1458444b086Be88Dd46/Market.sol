// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC1155Receiver.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./IDigitalCert.sol";
import "./DigitalCertLib.sol";
import "./MarketLib.sol";

contract Market is AccessControl, IERC1155Receiver, ReentrancyGuard {

    IERC20 token;
    IDigitalCert digitalCert;
    address public ownerAddress;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private redeemCounter = 0;

    /* digital cert id => is paused */
    mapping(uint256 => bool) private certIdToPaused;

    /* redeem id => MarketLib.Redeem struct */
    mapping(uint256 => MarketLib.Redeemed) private redeemIdToRedeemed;

    /* wallet addres => redeem id */
    mapping(address => uint256[]) private customerAddressToRedeemId;

    event RedeemEvent(uint256 indexed certId, address indexed redeemer,uint256 redeemId, uint256 amount, uint256 price);

    modifier whenNotPaused(uint256 id) {
        require(!certIdToPaused[id], "this certificated is paused");
        _;
    }
    constructor(address tokenAddress, address digitalCertAddress, address newOwnerAddress, address minter1, address minter2 ) {
      token = IERC20(tokenAddress);
      digitalCert = IDigitalCert(digitalCertAddress);

      _grantRole(DEFAULT_ADMIN_ROLE, newOwnerAddress);
      _grantRole(MINTER_ROLE, newOwnerAddress);
      _grantRole(MINTER_ROLE, minter1);
      _grantRole(MINTER_ROLE, minter2);
      ownerAddress = newOwnerAddress;
    }

    function setPauseForCertId(uint256 certId, bool isPaused) external onlyRole(MINTER_ROLE) {
        certIdToPaused[certId] = isPaused;
    }

    function onRedeem(uint256 certId, uint256 amount) external nonReentrant whenNotPaused(certId) {
        require(!Address.isContract(msg.sender), "caller must be person");
        require(digitalCert.balanceOf(address(this), certId) >= amount, "amount of cert is not enough");
        DigitalCertLib.DigitalCertificateRes memory cert = digitalCert.getDigitalCertificate(certId, address(this));
        require(cert.expire >= block.timestamp, "this cert is expired");
        uint256 cost = cert.price * amount;
        require(token.balanceOf(msg.sender) >= cost, "your balance of super x token is't enough");
        redeemCounter += 1;
        uint256 redeemId = redeemCounter;
        MarketLib.Redeemed memory redeemItem = MarketLib.Redeemed({
             redeemedId: redeemId,
            redeemer: msg.sender,
            certId: certId,
            amount: amount
        });
        token.transferFrom(msg.sender, ownerAddress, cost);
        digitalCert.burn(address(this),certId, amount);
        redeemIdToRedeemed[redeemId] = redeemItem;
        customerAddressToRedeemId[msg.sender].push(redeemId);
        emit RedeemEvent(certId, msg.sender,redeemId, amount, cert.price);
    }

    function burnFor(uint256 certId, uint256 burnAmount) external onlyRole(MINTER_ROLE) {
        require(digitalCert.balanceOf(address(this), certId) >= burnAmount);
        digitalCert.burn(address(this),certId, burnAmount);
    }

    function burnBatchFor(uint256[] calldata certIds, uint256[] calldata burnAmounts) external onlyRole(MINTER_ROLE) {
        digitalCert.burnBatch(address(this), certIds, burnAmounts);
    }

    function getLastRedeemId() public view returns(uint256) {
        return redeemCounter;
    }

    function isDigitalCertPaused(uint256 certId) public view returns(bool) {
        return certIdToPaused[certId];
    }

    function getRedeemByRedeemId(uint256 redeemId) public view returns (MarketLib.Redeemed memory) {
        return redeemIdToRedeemed[redeemId];
    }

    function getRedeemIdsByAddress(address customer) public view returns(uint256[] memory) {
        return customerAddressToRedeemId[customer];
    }

    // require for reciever
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

 
}
