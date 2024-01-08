// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./Create2.sol";
import "./PoolAddress.sol";
import "./IBentoBoxFactory.sol";
import "./IMisoMarket.sol";
import "./INFPreIPOToken.sol";
//import "./INFPreIPOCert.sol";
import "./IINFPermissionManager.sol";
import "./IPointList.sol";

contract INFFactory is AccessControlEnumerable {
    address private constant UNIV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address private constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address private constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    uint24 private constant FEE = 3000;

    struct PreIPOToken {
        address token;
        address cert;
    }
    // Issuer currently can only issue new tokens/certs, but cannot manage other owners'
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    mapping(string => PreIPOToken) public tokens;
    string[] public tokenSymbols;

    /// @notice Auctions created using factory.
    address[] public auctions;

    IINFPermissionManager private immutable permissionManager;
    IPointList private immutable pointListAdapter;
    IBentoBoxFactory private immutable bentoBox;

    /// @notice Event emitted when auction is created using template id.
    event MarketCreated(address indexed owner, address indexed addr, address indexed marketTemplate);

    constructor(IINFPermissionManager _permissionManager, IPointList _pointListAdapter, IBentoBoxFactory _bentoBox, address to) {
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _setupRole(ISSUER_ROLE, to);

        permissionManager = _permissionManager;
        pointListAdapter = _pointListAdapter;
        bentoBox = _bentoBox;
    }

    function issue(
        string memory name,
        string memory symbol,
        uint256 shares,
        address tradingToken
        //string memory signature
    )
        public
        onlyRole(ISSUER_ROLE)
    {
        // TODO: Read the decimals from somewhere
        uint256 amount = shares * 10 ** 18;
        PreIPOToken storage tokenObj = tokens[symbol];
        if (tokenObj.token == address(0)) {
            // New creation of token
            INFPreIPOToken wToken = new INFPreIPOToken(msg.sender, name, symbol, amount, address(permissionManager));
            tokenObj.token = address(wToken);
            tokenSymbols.push(symbol);
            permissionManager.setFeeExempt(PoolAddress.computeAddress(UNIV3Factory, PoolAddress.getPoolKey(address(wToken), tradingToken, FEE)), false, true);
            permissionManager.setFeeExempt(address(this), true, true);
            permissionManager.whitelistInvestor(POSITION_MANAGER, true);
            permissionManager.whitelistInvestor(QUOTER, true);
        } else {
            // Minting new shares
            INFPreIPOToken wToken = INFPreIPOToken(tokenObj.token);
            wToken.mint(msg.sender, amount);
        }
        /** WILL REVISIT
        // Create new certificate NFT type
        INFPreIPOCert wCert;
        if (tokenObj.cert == address(0)) {
            wCert = new INFPreIPOCert(name, symbol);
            tokenObj.cert = address(wCert);
        } else {
            wCert = INFPreIPOCert(tokenObj.cert);
        }
        // Issue to self first, then encode data
        wCert.issueCert(msg.sender, shares, signature, true);
        **/
    }

    function whitelistUniPool(address token1, address token2) external onlyRole(ISSUER_ROLE) {
        permissionManager.setFeeExempt(PoolAddress.computeAddress(UNIV3Factory, PoolAddress.getPoolKey(address(token1), token2, FEE)), false, true);
    }

    function whitelistClone(bytes calldata data, address implementation) external onlyRole(ISSUER_ROLE){
        permissionManager.setFeeExempt(computeAddress(data, implementation), true, true);
    }

    function createMarket(
        address template,
        IERC20 _token,
        uint256 _tokenSupply,
        bytes calldata _data
    )
        external onlyRole(ISSUER_ROLE) returns (address newMarket)
    {

        newMarket = bentoBox.deploy(template, _data, true);
        auctions.push(newMarket);
        emit MarketCreated(msg.sender, newMarket, template);

        if (_tokenSupply > 0) {
            _token.transferFrom(msg.sender, address(this), _tokenSupply);
            require(_token.approve(newMarket, _tokenSupply), "1");
        }

        permissionManager.setFeeExempt(newMarket, true, true);
        IMisoMarket(newMarket).initMarket(_data);

        if (_tokenSupply > 0) {
            uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
            if (remainingBalance > 0) {
                _token.transfer(msg.sender, remainingBalance);
            }
        }
        return newMarket;
    }

    function allTokenSymbols() public view returns (string[] memory) {
        return tokenSymbols;
    }

    function computeAddress(bytes calldata data, address implementation)
        public
        view
        returns (address)
    {
        return
            Create2.computeAddress(
                keccak256(data),
                keccak256(getContractCreationCode(implementation)),
                0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
            );
    }
    function getContractCreationCode(address logic)
        internal
        pure
        returns (bytes memory)
    {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(logic);
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, prefix, targetBytes, suffix);
    }
    
    function encodeMarket(address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _wallet) public view returns (bytes memory) {
            return abi.encode( _funder,
        _token,
        _paymentCurrency,
         _totalTokens,
         _startTime,
         _endTime,
         _rate,
         _goal,
         _admin,
         pointListAdapter,
        _wallet);
    }
}
