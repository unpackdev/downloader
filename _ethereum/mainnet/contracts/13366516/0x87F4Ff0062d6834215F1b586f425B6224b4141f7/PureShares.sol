//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

// import ERC20
import "./ERC20.sol";
import "./Ownable.sol";

contract PureShares is ERC20, Ownable {

    // minter can also burn.
    mapping (address => bool) public minter;

    modifier onlyMinterAndOwner() {
        require(msg.sender == owner() || minter[msg.sender], "msg.sender has to be owner or minter");
        _;
    }

    constructor(
        string memory _erc20Name, string memory _erc20Symbol
    ) ERC20(_erc20Name, _erc20Symbol) {}

    function mint(address _target, uint256 _shares) public onlyMinterAndOwner {
        _mint(_target, _shares);
    }

    function burn(address _target, uint256 _shares) public onlyMinterAndOwner {
        _burn(_target, _shares);
    }

    function mintBatch(address[] memory _target, uint256[] memory _shares) public onlyMinterAndOwner {
        require(_target.length == _shares.length, "address list and shares list must match their length");
        for(uint256 i = 0 ; i < _target.length; i++) {
            _mint(_target[i], _shares[i]);
        }
    }

    function setMinter(address target, bool flag) public onlyOwner {
        minter[target] = flag;
    }

}