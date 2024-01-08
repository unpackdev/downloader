// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Configurable.sol";
import "./ONE.sol";
import "./ONS.sol";
import "./Constant.sol";
import "./Vault.sol";
import "./SafeERC20.sol";

contract OneMinter is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint internal constant INITIAL_INPUT = 1e27;

    Vault public vault;
    ONE public one;
    ONS public ons;
    IAETH public aEth;

    mapping (address => uint) internal _aEthBalances;
    mapping (address => uint) internal _onsBalances;
    mapping (address => uint) internal _aEthRIOs;
    mapping (address => uint) internal _onsRIOs;
    mapping (uint => uint) internal _aEthRioIn;
    mapping (uint => uint) internal _onsRioIn;
    uint internal _aEthRound;
    uint internal _onsRound;

    function __OneMinter_init(address governor_, address vault_) external initializer {
        __Governable_init_unchained(governor_);
        __OneMinter_init_unchained(vault_);
    }

    function __OneMinter_init_unchained(address vault_) public governance {
        vault = Vault(vault_);
        one = ONE(vault.one());
        ons = ONS(vault.ons());
        aEth = IAETH(vault.aEth());
        aEth.approve(address(vault), uint(-1));
        ons.approve(address(vault), uint(-1));
        _aEthRound = _onsRound = 1;
        _aEthRioIn[1] = packRIO(1, INITIAL_INPUT, 0);
        _onsRioIn [1] = packRIO(1, INITIAL_INPUT, 0);
    }

    //struct RIO {
    //    uint32  round;
    //    uint112 input;
    //    uint112 output;
    //}

    function packRIO(uint256 round, uint256 input, uint256 output) internal pure virtual returns (uint256) {
        require(round <= uint32(-1) && input <= uint112(-1) && output <= uint112(-1), 'RIO OVERFLOW');
        return round << 224 | input << 112 | output;
    }

    function unpackRIO(uint256 rio) internal pure virtual returns (uint256 round, uint256 input, uint256 output) {
        round  = rio >> 224;
        input  = uint112(rio >> 112);
        output = uint112(rio);
    }

    function totalSupply() external view returns (uint aEthSupply, uint onsSupply) {
        aEthSupply = aEth.balanceOf(address(this));
        onsSupply  =  ons.balanceOf(address(this));
    }

    function balanceOf(address acct) public view returns (uint aEthBal, uint onsBal) {
        uint rio = _aEthRIOs[acct];
        (uint r, uint i, ) = unpackRIO(rio);
        uint RIO = _aEthRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            aEthBal = _aEthBalances[acct].mul(I).div(i);
        } else
            aEthBal = _aEthBalances[acct];

        rio = _onsRIOs[acct];
        (r, i, ) = unpackRIO(rio);
        RIO = _onsRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            onsBal = _onsBalances[acct].mul(I).div(i);
        } else
            onsBal = _onsBalances[acct];
    }

    event Purchase(address acct, uint aEthVol, uint onsVol);

    function cancel() public {
        uint aEthVol = _aEthBalances[msg.sender];
        uint onsVol = _onsBalances[msg.sender];
        _aEthBalances[msg.sender] = _aEthBalances[msg.sender].sub(aEthVol);
        _onsBalances [msg.sender] = _onsBalances [msg.sender].sub(onsVol);
        emit Cancel(msg.sender, aEthVol, onsVol);

        aEth.transfer(msg.sender, aEthVol);
        ons.transfer (msg.sender, onsVol);
    }

    event Cancel(address acct, uint aEthVol, uint onsVol);
    event Mint(address acct, uint oneVol);
    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);
}
