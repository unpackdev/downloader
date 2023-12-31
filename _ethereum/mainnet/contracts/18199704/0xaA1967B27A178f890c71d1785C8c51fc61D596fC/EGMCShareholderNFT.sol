// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";

import "./IEGMCShareholderPool.sol";

contract EGMCShareholderNFT is ERC1155, AccessControl {
    using Address for address payable;
    using SafeMath for uint;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string public name = "EGMC Shareholder NFT";
    string public symbol = "EGMCSHARENFT";

    address public shareholderPool;
    uint public currentPrice = 0.05 ether;
    uint public priceTick = 0.005 ether;
    uint public initialSupply = 1000;
        
    address private immutable admin;
    address private fund;

    event Purchased(
        address indexed account,
        uint id,
        uint amount
    );

    constructor() ERC1155("https://api.egmc.info/token/{id}") {
        admin = _msgSender();

        _mint(address(this), 1, initialSupply.sub(100), "");
        _mint(admin, 1, 100, "");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    
    /** VIEW FUNCTIONS */

    function getTotalCost(uint amount) public view returns (uint) {
        if (amount == 0) return 0;

        return currentPrice * amount +
            ((amount * (amount - 1) / 2) * priceTick);
    }

    /** PUBLIC FUNCTIONS */

    function purchase(uint amount, bool autoStake) external payable {
        require(address(fund) != address(0), "Fund address not set");
        require(amount > 0, "Amount must be more than zero");
        require(amount <= 100, "Amount must be less or equal to 100");
        require(balanceOf(address(this), 1) >= amount, "Amount can not be purchased");

        uint cost = getTotalCost(amount);
        require(msg.value >= cost, "Value is too low");
        currentPrice = currentPrice + priceTick * amount;

        payable(fund).sendValue(msg.value);

        if (autoStake) {
            _safeTransferFrom(address(this), shareholderPool, 1, amount, "");
            IEGMCShareholderPool(shareholderPool).depositFor(_msgSender(), amount);
        } else {
            _safeTransferFrom(address(this), _msgSender(), 1, amount, "");
        }

        emit Purchased(_msgSender(), 1, amount);
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://api.egmc.info/token/",
                Strings.toString(_tokenid)
            )
        );
    }

    /** RESTRICTED FUNCTIONS */

    function setFund(address _fund) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fund = _fund;
    }

    function mint(address to, uint id, uint amount, bytes calldata data) external onlyRole(MANAGER_ROLE) {
        return _mint(to, id, amount, data);
    }

    function burn(address from, uint id, uint amount) external onlyRole(MANAGER_ROLE) {
        return _burn(from, id, amount);
    }

    function setShareholderPool(address _shareholderPool) external onlyRole(MANAGER_ROLE) {
        shareholderPool = _shareholderPool;
    }

    function setPriceTick(uint _priceTick) external onlyRole(MANAGER_ROLE) {
        priceTick = _priceTick;
    }

    function recover(address _token) external onlyRole(MANAGER_ROLE) {
        IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
    }

    /** INTERFACE FUNCTIONS */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}