// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./Withdrawable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC777Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC1820RegistryUpgradeable.sol";

contract Erc20Vault is
    Initializable,
    Withdrawable,
    IERC777RecipientUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    IERC1820RegistryUpgradeable constant private _erc1820 = IERC1820RegistryUpgradeable(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 constant private Erc777Token_INTERFACE_HASH = keccak256("ERC777Token");

    EnumerableSetUpgradeable.AddressSet private supportedTokens;
    address public PNETWORK;
    IWETH public weth;
    bytes4 public ORIGIN_CHAIN_ID;

    event PegIn(
        address _tokenAddress,
        address _tokenSender,
        uint256 _tokenAmount,
        string _destinationAddress,
        bytes _userData,
        bytes4 _originChainId,
        bytes4 _destinationChainId
    );

    function initialize(
        address _weth,
        address[] memory _tokensToSupport,
        bytes4 _originChainId
    )
        public
        initializer
    {
        PNETWORK = msg.sender;
        for (uint256 i = 0; i < _tokensToSupport.length; i++) {
            supportedTokens.add(_tokensToSupport[i]);
        }
        weth = IWETH(_weth);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        ORIGIN_CHAIN_ID = _originChainId;
    }

    modifier onlyPNetwork() {
        require(msg.sender == PNETWORK, "Caller must be PNETWORK address!");
        _;
    }

    modifier onlySupportedTokens(address _tokenAddress) {
        require(supportedTokens.contains(_tokenAddress), "Token at supplied address is NOT supported!");
        _;
    }

    function setWeth(address _weth) external onlyPNetwork {
        weth = IWETH(_weth);
    }

    function setPNetwork(address _pnetwork) external onlyPNetwork {
        require(_pnetwork != address(0), "Cannot set the zero address as the pNetwork address!");
        PNETWORK = _pnetwork;
    }

    function isTokenSupported(address _token) external view returns(bool) {
        return supportedTokens.contains(_token);
    }

    function _owner() internal view override returns(address) {
        return PNETWORK;
    }

    function adminWithdrawAllowed(address asset) internal override view returns(uint) {
        return supportedTokens.contains(asset) ? 0 : super.adminWithdrawAllowed(asset);
    }

    function addSupportedToken(
        address _tokenAddress
    )
        external
        onlyPNetwork
        returns (bool SUCCESS)
    {
        supportedTokens.add(_tokenAddress);
        return true;
    }

    function removeSupportedToken(
        address _tokenAddress
    )
        external
        onlyPNetwork
        returns (bool SUCCESS)
    {
        return supportedTokens.remove(_tokenAddress);
    }

    function getSupportedTokens() external view returns(address[] memory res) {
        res = new address[](supportedTokens.length());
        for (uint256 i = 0; i < supportedTokens.length(); i++) {
            res[i] = supportedTokens.at(i);
        }
    }

    function pegIn(
        uint256 _tokenAmount,
        address _tokenAddress,
        string calldata _destinationAddress,
        bytes4 _destinationChainId
    )
        external
        returns (bool)
    {
        return pegIn(_tokenAmount, _tokenAddress, _destinationAddress, "", _destinationChainId);
    }

    function pegIn(
        uint256 _tokenAmount,
        address _tokenAddress,
        string memory _destinationAddress,
        bytes memory _userData,
        bytes4 _destinationChainId
    )
        public
        onlySupportedTokens(_tokenAddress)
        returns (bool)
    {
        require(_tokenAmount > 0, "Token amount must be greater than zero!");
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        emit PegIn(
            _tokenAddress,
            msg.sender,
            _tokenAmount,
            _destinationAddress,
            _userData,
            ORIGIN_CHAIN_ID,
            _destinationChainId
        );
        return true;
    }

    /**
     * @dev Implementation of IERC777Recipient.
     */
    function tokensReceived(
        address /*operator*/,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata /*operatorData*/
    )
        external
        override
        onlySupportedTokens(msg.sender)
    {
        require(to == address(this), "Token receiver is not this contract");
        if (userData.length > 0) {
            require(amount > 0, "Token amount must be greater than zero!");
            (bytes32 tag, string memory _destinationAddress, bytes4 _destinationChainId) = abi.decode(
                userData,
                (bytes32, string, bytes4)
            );
            require(
                tag == keccak256("ERC777-pegIn"),
                "Invalid tag for automatic pegIn on ERC777 send"
            );
            emit PegIn(
                msg.sender,
                from,
                amount,
                _destinationAddress,
                userData,
                ORIGIN_CHAIN_ID,
                _destinationChainId
            );
        }
    }

    function pegInEth(
        string calldata _destinationAddress,
        bytes4 _destinationChainId
    )
        external
        payable
        returns (bool)
    {
        return pegInEth(_destinationAddress, _destinationChainId, "");
    }

    function pegInEth(
        string memory _destinationAddress,
        bytes4 _destinationChainId,
        bytes memory _userData
    )
        public
        payable
        returns (bool)
    {
        require(supportedTokens.contains(address(weth)), "WETH is NOT supported!");
        require(msg.value > 0, "Ethers amount must be greater than zero!");
        weth.deposit{ value: msg.value }();
        emit PegIn(
            address(weth),
            msg.sender,
            msg.value,
            _destinationAddress,
            _userData,
            ORIGIN_CHAIN_ID,
            _destinationChainId
        );
        return true;
    }

    function pegOutWeth(
        address payable _tokenRecipient,
        uint256 _tokenAmount,
        bytes memory _userData
    )
        internal
        returns (bool)
    {
        weth.withdraw(_tokenAmount);
        // NOTE: This is the latest recommendation (@ time of writing) for transferring ETH. This no longer relies
        // on the provided 2300 gas stipend and instead forwards all available gas onwards.
        // SOURCE: https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now
        (bool success, ) = _tokenRecipient.call{ value: _tokenAmount }(_userData);
        require(success, "ETH transfer failed when pegging out wETH!");
        return success;
    }

    function pegOut(
        address payable _tokenRecipient,
        address _tokenAddress,
        uint256 _tokenAmount
    )
        public
        onlyPNetwork
        returns (bool)
    {
        if (_tokenAddress == address(weth)) {
            pegOutWeth(_tokenRecipient, _tokenAmount, "");
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransfer(_tokenRecipient, _tokenAmount);
        }
        return true;
    }

    function pegOut(
        address payable _tokenRecipient,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _userData
    )
        external
        onlyPNetwork
        returns (bool success)
    {
        if (_tokenAddress == address(weth)) {
            pegOutWeth(_tokenRecipient, _tokenAmount, _userData);
        } else {
            address erc777Address = _erc1820.getInterfaceImplementer(_tokenAddress, Erc777Token_INTERFACE_HASH);
            if (erc777Address == address(0)) {
                return pegOut(_tokenRecipient, _tokenAddress, _tokenAmount);
            } else {
                IERC777Upgradeable(erc777Address).send(_tokenRecipient, _tokenAmount, _userData);
                return true;
            }
        }
    }

    receive() external payable {
        require(msg.sender == address(weth));
    }

    function changeOriginChainId(
        bytes4 _newOriginChainId
    )
        public
        onlyPNetwork
        returns (bool success)
    {
        ORIGIN_CHAIN_ID = _newOriginChainId;
        return true;
    }
}
