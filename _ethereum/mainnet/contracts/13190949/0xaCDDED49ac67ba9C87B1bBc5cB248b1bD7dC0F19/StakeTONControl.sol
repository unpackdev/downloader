//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ITokamakStakerUpgrade.sol";
import "./IIERC20.sol";
import "./IISeigManager.sol";
import "./IIIDepositManager.sol";
import "./SafeMath.sol";
import "./AccessibleCommon.sol";

contract StakeTONControl is AccessibleCommon {
    using SafeMath for uint256;

    address public ton;
    address public wton;
    address public tos;
    address public depositManager;
    address public seigManager;
    address public layer2;
    uint256 public countStakeTons;
    mapping(uint256 => address) public stakeTons;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "TokamakStaker: zero address");
        _;
    }
    modifier avaiableIndex(uint256 _index) {
        require(_index > 0, "StakeTONControl: can't use zero index");
        require(_index <= countStakeTons, "StakeTONControl: exceeded maxIndex");
        _;
    }

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function setInfo(
        address _ton,
        address _wton,
        address _tos,
        address _depositManager,
        address _seigManager,
        address _layer2,
        uint256 _countStakeTons
    ) external onlyOwner {
        ton = _ton;
        wton = _wton;
        tos = _tos;
        depositManager = _depositManager;
        seigManager = _seigManager;
        layer2 = _layer2;
        countStakeTons = _countStakeTons;
    }

    function deleteStakeTon(uint256 _index)
        external
        onlyOwner
        avaiableIndex(_index)
    {
        delete stakeTons[_index];
    }

    function addStakeTon(uint256 _index, address addr)
        external
        onlyOwner
        avaiableIndex(_index)
    {
        stakeTons[_index] = addr;
    }

    function addStakeTons(address[] calldata _addr) external onlyOwner {
        require(_addr.length > 0, "StakeTONControl: zero length");
        require(
            _addr.length == countStakeTons,
            "StakeTONControl: diff countStakeTons"
        );

        for (uint256 i = 1; i <= _addr.length; i++) {
            stakeTons[i] = _addr[i - 1];
        }
    }

    function canSwappedWTON(uint256 _index)
        public
        view
        nonZeroAddress(depositManager)
        nonZeroAddress(seigManager)
        nonZeroAddress(layer2)
        returns (uint256)
    {
        if (stakeTons[_index] == address(0)) return 0;
        uint256 endBlock = ITokamakStakerUpgrade(stakeTons[_index]).endBlock();

        if (block.number < endBlock) {
            uint256 _amountWTON = IIERC20(wton).balanceOf(stakeTons[_index]);
            uint256 _amountTON = IIERC20(ton).balanceOf(stakeTons[_index]);
            uint256 totalStakedAmount =
                ITokamakStakerUpgrade(stakeTons[_index]).totalStakedAmount();

            uint256 stakeOf = 0;

            stakeOf = IISeigManager(seigManager).stakeOf(
                layer2,
                stakeTons[_index]
            );
            stakeOf = stakeOf.add(
                IIIDepositManager(depositManager).pendingUnstaked(
                    layer2,
                    stakeTons[_index]
                )
            );
            uint256 holdAmount = _amountWTON;
            if (_amountTON > 0)
                holdAmount = holdAmount.add(_amountTON.mul(10**9));

            uint256 totalHoldAmount = holdAmount.add(stakeOf);

            if (totalHoldAmount.sub(100) > totalStakedAmount.mul(10**9)) {
                if (stakeOf.add(100) > totalStakedAmount.mul(10**9))
                    return holdAmount;
                else {
                    uint256 amount =
                        holdAmount.sub(
                            totalStakedAmount.mul(10**9).sub(stakeOf).sub(100)
                        );
                    return amount;
                }
            } else {
                return 0;
            }
        } else return 0;
    }

    function withdrawLayer2(uint256 _index) public nonZeroAddress(layer2) {
        require(
            stakeTons[_index] != address(0),
            "StakeTONControl: zero stakeTons"
        );

        (uint256 count, uint256 amount) =
            ITokamakStakerUpgrade(stakeTons[_index])
                .canTokamakProcessUnStakingCount(layer2);

        if (count > 0 && amount > 0)
            ITokamakStakerUpgrade(stakeTons[_index]).tokamakProcessUnStaking(
                layer2
            );
    }

    function swapTONtoTOS(uint256 _index, uint256 _amountOut) public  avaiableIndex(_index) {
        uint256 amountIn = canSwappedWTON(_index);
        if (amountIn > 0) {
            uint256 deadline = block.timestamp + 1000;
            ITokamakStakerUpgrade(stakeTons[_index]).exchangeWTONtoTOS(
                amountIn,
                _amountOut,
                deadline,
                0,
                0
            );
        }
    }

    function withdrawLayer2AndSwapTOS(uint256 _index, uint256 _amountOut)
        public
        nonZeroAddress(layer2)
    {
        withdrawLayer2(_index);
        swapTONtoTOS(_index, _amountOut);
    }

    function withdrawLayer2All() public nonZeroAddress(layer2)  {
        (bool can, bool[] memory canProcessUnStaking) = canWithdrawLayer2All();
        require(can, "StakeTONControl: no available withdraw from layer2");
        for (uint256 i = 1; i <= countStakeTons; i++) {
            if(canProcessUnStaking[i-1]) withdrawLayer2(i);
        }
    }

    function SwapAll(uint256[] memory amountOuts) public {
        require(amountOuts.length == countStakeTons, "StakeTONControl: diff length");
        for (uint256 i = 1; i <= countStakeTons; i++) {
            swapTONtoTOS(i, amountOuts[i-1]);
        }
    }

    function withdrawLayer2AllAndSwapAll(uint256[] memory amountOuts) external nonZeroAddress(layer2)  {

        withdrawLayer2All();
        SwapAll(amountOuts);
    }


    function canWithdrawLayer2All()
        public
        view
        nonZeroAddress(layer2)
        returns (bool can, bool[] memory canProcessUnStaking)
    {
        can = false;
        canProcessUnStaking = new bool[](countStakeTons);
        for (uint256 i = 1; i <= countStakeTons; i++) {
            if(ITokamakStakerUpgrade(stakeTons[i]).tokamakLayer2() == layer2){
                (uint256 count, uint256 amount) = ITokamakStakerUpgrade(stakeTons[i]).canTokamakProcessUnStakingCount(layer2);
                if (count > 0 && amount > 0) {
                    if(!can) can = true;
                    canProcessUnStaking[i-1] = true;
                } else {
                    canProcessUnStaking[i-1] = false;
                }
            }else{
                canProcessUnStaking[i-1] = false;
            }
        }
    }
}
