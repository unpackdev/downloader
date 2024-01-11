// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./IPresaleFactory.sol";
import "./IMoonForceSwapLocker.sol";
import "./IMoonForceSwapFactory.sol";
import "./IMoonForceSwapPair.sol";
import "./IPYESwapRouter.sol";
import "./IERC20.sol";
import "./IToken.sol";

contract PresaleLockForwarder is Ownable {
    
    IPresaleFactory public PRESALE_FACTORY;
    IMoonForceSwapLocker public MOON_FORCE_LOCKER;
    IMoonForceSwapFactory public MOON_FORCE_FACTORY;
    IPYESwapRouter public PYESwapRouter;
    
    constructor() public {
        PRESALE_FACTORY = IPresaleFactory(0x931d82cc98F8Bca90949382A619295Ed5467C2F9);
        MOON_FORCE_LOCKER = IMoonForceSwapLocker(0x60F90Ad88E50B562b39C0f33aD579bc91e0c09A2);
        MOON_FORCE_FACTORY = IMoonForceSwapFactory(0xA2F8f1FAb81300c48208dc0aE540c6675d19f4cd);
        PYESwapRouter = IPYESwapRouter(0x4F71E29C3D5934A15308005B19Ca263061E99616);
    }

    /**
        Send in _token0 as the PRESALE token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a presale is running, but no one should have access to the presale token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function moonForcePairIsInitialised (address _token0, address _token1) public view returns (bool) {
        address pairAddress = MOON_FORCE_FACTORY.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }
    
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external {
        require(PRESALE_FACTORY.presaleIsRegistered(msg.sender), 'PRESALE NOT REGISTERED');
        address pair = MOON_FORCE_FACTORY.getPair(address(_baseToken), address(_saleToken));
        bool supportsTokenFee = false;
        try IToken(address(_saleToken)).getTotalFee() { supportsTokenFee = true; } catch { supportsTokenFee = false; }
        if (pair == address(0)) {
            MOON_FORCE_FACTORY.createPair(address(_saleToken), address(_baseToken), supportsTokenFee);
            pair = MOON_FORCE_FACTORY.getPair(address(_baseToken), address(_saleToken));
        }
        
        // TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        // TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(pair), _saleAmount);
        // IMoonForceSwapPair(pair).mint(address(this));

        TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(this), _baseAmount);
        TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(this), _saleAmount);
        TransferHelper.safeApprove(address(_baseToken), address(PYESwapRouter), _baseAmount);
        TransferHelper.safeApprove(address(_saleToken), address(PYESwapRouter), _saleAmount);
        PYESwapRouter.addLiquidity(address(_saleToken), address(_baseToken), supportsTokenFee, _saleAmount, _baseAmount, 0, 0, address(this), block.timestamp);
        uint256 totalLPTokensMinted = IMoonForceSwapPair(pair).balanceOf(address(this));
        require(totalLPTokensMinted != 0 , "LP creation failed");
    
        TransferHelper.safeApprove(pair, address(MOON_FORCE_LOCKER), totalLPTokensMinted);
        uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;
        MOON_FORCE_LOCKER.lockLPToken(pair, totalLPTokensMinted, unlock_date, address(0), true, _withdrawer);
    }
    
}
