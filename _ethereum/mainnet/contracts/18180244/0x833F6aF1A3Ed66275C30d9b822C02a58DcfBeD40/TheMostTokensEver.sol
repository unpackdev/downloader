//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721.sol";
import "./Base64.sol";

contract TheMostTokensEver is IERC721 {

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        address indexed fromAddress, 
        address indexed toAddress);

    mapping(address _owner => uint256 balance) public balanceOf;
    mapping(uint256 tokenId => address _owner) private _ownerOf;
    mapping(uint256 tokenId => address _approved) public getApproved;
    mapping(address _owner => mapping(address _operator => bool _approved)) public isApprovedForAll;

    address public constant DEFAULT_OWNER = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address public constant owner = 0x3C5E6B4292Ed35e8973400bEF77177A9e84e8E6e;
    string public name = "The Most Tokens Ever";
    string public symbol = "TMTE";

    uint256 public constant totalSupply = 0; //2^256 overflows to 0

    constructor() {
        balanceOf[owner] = 1;
        _ownerOf[0] = owner;
        emit Transfer(address(0), owner, 0);

        balanceOf[DEFAULT_OWNER] = type(uint256).max;
        emit ConsecutiveTransfer(1, type(uint256).max, address(0), DEFAULT_OWNER);
        isApprovedForAll[DEFAULT_OWNER][address(this)] = true;
        emit ApprovalForAll(DEFAULT_OWNER, address(this), true);
    }

    function claim(uint256 _tokenId) public payable {
        if(_ownerOf[_tokenId] != address(0)) revert();
        this.transferFrom(DEFAULT_OWNER, msg.sender, _tokenId);
    }

    function ownerOf(uint256 _tokenId) public view returns(address _owner) {
        _owner = _ownerOf[_tokenId];
        if(_owner == address(0)) _owner = DEFAULT_OWNER;
    }

    function tokenURI(uint256 _tokenId) public pure returns (string memory _uri) {
        string memory _tokenString = _toString(_tokenId);
        string memory _svgString = Base64.encode(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMidYMin slice" viewBox="0 0 728 400"><path d="M0 0h728v400H0z" fill="white" /><defs><path id="curve" d="m 363.32001,203.97319 c 3.64959,3.6496 -3.11901,6.72017 -6.06587,6.06587 -7.98584,-1.77311 -9.26961,-12.00196 -6.06587,-18.19761 5.73073,-11.08257 20.6122,-12.38089 30.32935,-6.06587 14.26032,9.26756 15.58439,29.33925 6.06586,42.4611 -12.6867,17.48936 -38.10776,18.82717 -54.59283,6.06585 -20.74479,-16.05881 -22.09029,-46.89603 -6.06585,-66.72457 19.40773,-24.01503 55.69543,-25.36517 78.85631,-6.06585 27.2943,22.74358 28.64744,64.50177 6.06585,90.98806 -26.07135,30.57946 -73.31275,31.93464 -103.1198,6.06584 -33.86866,-29.39378 -35.22529,-82.12698 -6.06584,-115.25154 32.7125,-37.16075 90.94358,-38.51845 127.38328,-6.06584 40.45497,36.02855 41.81347,99.76197 6.06583,139.51502 -39.3426,43.75082 -108.58173,45.10994 -151.64676,6.06583 -47.04792,-42.65512 -48.40753,-117.40258 -6.06582,-163.7785 45.96644,-50.346019 126.2243,-51.706017 175.91024,-6.06582 53.64492,49.27682 55.00524,135.04673 6.06582,188.04198 -52.58642,56.94449 -143.86976,58.30507 -200.17373,6.06582 C 199.9556,251.19757 198.5948,154.3997 254.13437,94.787494 313.33819,31.24235 415.65155,29.881364 478.57158,88.721685 532.16254,138.83784 545.45065,220.64134 512.35921,285.79363" /></defs><text font-family="monospace" font-size="20" fill="black"><textPath id="text" xlink:href="#curve">', _tokenString, '</textPath></text></svg>')));
        _uri = string.concat("data:application/json,",'{"name": "The Most Tokens Ever - ', _tokenString, '","description": "The most tokens ever minted on one single Ethereum contract. Ever.","image_data":"data:image/svg+xml;base64,',_svgString,'"}');
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata) public payable {
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        transferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        if(_to == address(0)) revert();
        _from = _validate(msg.sender, _from, _tokenId);

        if(_from != _to) {
            uint256 toBalance = balanceOf[_to];
            if(toBalance == type(uint256).max) revert();
            uint256 fromBalance = balanceOf[_from];

            unchecked {
                ++toBalance;
                --fromBalance;
            }

            balanceOf[_to] = toBalance;
            balanceOf[_from] = fromBalance;
            _ownerOf[_tokenId] = _to;

            if(getApproved[_tokenId] != address(0)) {
                getApproved[_tokenId] = address(0);
                emit Approval(_to, address(0), _tokenId);
            }
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        require(msg.sender == _ownerOf[_tokenId]);
        getApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public payable {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function withdraw() public payable {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success);
    }

    function _validate(address _operator, address _from, uint256 _tokenId) internal view returns (address _newFrom) {
        address _owner = _ownerOf[_tokenId];
        if(_owner == address(0)) _owner = DEFAULT_OWNER;
        if(msg.sender != _owner) {
            if(!isApprovedForAll[_owner][_operator]) {
                if(getApproved[_tokenId] != _operator) {
                    revert();
                }
            }
        }
        if(_from != _owner) revert();
        _newFrom = _owner;
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }
}