pragma solidity >=0.6.0 <0.7.0;

import "./AccessControl.sol";

import "./IBondToken.sol";
import "./IDDP.sol";
import "./ERC721.sol";
import "./Initializable.sol";

import "./TokenAccessRoles.sol";


contract BondToken is IBondToken, AccessControl, ERC721, Initializable {
    using SafeMath for uint256;

    uint256 private constant INTEREST_PERCENT = 7;

    struct BondInfo {
        uint256 value;
        uint256 interestPerSec;
        uint256 maturityEnds;
    }

    /// all tokens values
    mapping(uint256 => BondInfo) private _bondInfo;

    /// value of all tokens summarized
    uint256 private _totalValue;

    /// sat address
    address private _sat;

    /// ddp address
    address private _ddp;

    constructor(string memory baseURI) public ERC721("EurxbBondToken", "EBND") {
        _setBaseURI(baseURI);
    }

    /// bond info accessors

    function getTokenInfo(uint256 tokenId) external view override
        returns (uint256 value, uint256 interest, uint256 maturity)
    {
        BondInfo memory info = _bondInfo[tokenId];
        return ( info.value, info.interestPerSec, info.maturityEnds );
    }

    function totalValue() external view returns (uint256) {
        return _totalValue;
    }

    function configure(address allowList, address sat, address ddp) external initializer {
        require(allowList != address(0), "list address is invalid");
        require(sat != address(0), "sat address is invalid");
        require(ddp != address(0), "ddp address is invalid");

        _setupRole(TokenAccessRoles.minter(), sat);
        _setupRole(TokenAccessRoles.transferer(), sat);

        _setupRole(TokenAccessRoles.burner(), ddp);
        _setupRole(TokenAccessRoles.transferer(), ddp);

        _ddp = ddp;
        _sat = sat;
    }

    function mint(
        uint256 tokenId,
        address to,
        uint256 value,
        uint256 maturity
    ) external override
    {
        require(
            hasRole(TokenAccessRoles.minter(), _msgSender()),
            "user is not allowed to mint"
        );

        _mint(to, tokenId);

        uint256 interestPerSec = value
        .mul(INTEREST_PERCENT).div(365 days).div(100);

        uint256 maturityEnds = block.timestamp.add(maturity);

        _bondInfo[tokenId] = BondInfo(
            {
                value: value,
                interestPerSec: interestPerSec,
                maturityEnds: maturityEnds
            });

        _totalValue = _totalValue.add(value);

        IDDP(_ddp).deposit(
            tokenId,
            value,
            maturityEnds,
            to
        );
    }

    function hasToken(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) external override(IBondToken) {
        require(
            hasRole(TokenAccessRoles.burner(), _msgSender()),
            "user is not allowed to burn tokens"
        );

        _burn(tokenId);

        uint256 value = _bondInfo[tokenId].value;
        delete _bondInfo[tokenId];
        _totalValue = _totalValue.sub(value);
    }

    // approval functions must be prohibited
    function approve(address, uint256) public override {
        revert("method is not supported");
    }

    function getApproved(uint256) public view override returns (address) {
        revert("method is not supported");
    }

    function setApprovalForAll(address, bool) public override {
        revert("method is not supported");
    }

    function isApprovedForAll(address, address)
        public
        view
        override
        returns (bool)
    {
        revert("method is not supported");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override
    {
        _safeTransferFrom(
            _msgSender(),
            from,
            to,
            tokenId,
            "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId) public override(IBondToken, ERC721)
    {
        _safeTransferFrom(
            _msgSender(),
            from,
            to,
            tokenId,
            "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override
    {
        _safeTransferFrom(
            _msgSender(),
            from,
            to,
            tokenId,
            _data);
    }

    function _safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private
    {
        require(
            hasRole(TokenAccessRoles.transferer(), sender),
            "user is not allowed to transfer tokens"
        );

        _safeTransfer(
            from,
            to,
            tokenId,
            _data);

        if (sender != _sat) {
            IERC721(_sat)
            .safeTransferFrom(
                from,
                to,
                tokenId,
                _data);
        }
    }
}
