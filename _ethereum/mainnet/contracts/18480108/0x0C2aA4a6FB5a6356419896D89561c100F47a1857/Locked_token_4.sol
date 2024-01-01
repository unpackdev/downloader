// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * Create By AZUR Team.
 * AzurLock built for the Azur ecosystem that you can use on "Azurswap.org"
 *
 *
 * It would be an honor to have you use it.
 ** Sincerely, Azureswap Senior Developer
 */


import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract AZURLockedToken is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    event AddTokentoLockedPoolEvent(
        address tokenAddress,
        address ownerLocked,
        uint256 startTime,
        uint256 endTime,
        uint256 amountToken,
        uint8 decimals,
        string tokenName,
        string tokenSymbol
    );

    event WithdrawTokenofFree(
        address tokenAddress,
        address ownerLocked,
        uint256 amountToken,
        uint256 withdrawTime,
        uint8 decimals,
        string tokenName,
        string tokenSymbol
    );
    event MakeFreeTokensEvent(
        address tokenAddress,
        address ownerLocked,
        uint256 amountToken,
        uint256 timeFreeTokens,
        uint8 decimals,
        string nameToken,
        string symbolToken
    );

    struct InfoLocked {
        uint256 startTime;
        uint256 endTime;
        uint256 amountLockedTokens;
        uint256 amountFreeTokens;
        uint8 decimals;
        string nameToken;
        string symbolToken;
    }

    mapping(address => mapping(address => InfoLocked)) private EachInfoLocked;
    mapping(address => mapping(address => bool)) private AllPairOfAddress;
    mapping(address => uint256) public NumberOfLockedAddress;
    mapping(address => address[]) LockedOfUser;

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor() {}

    function AddTokentoLockedPool(
        uint256 endTime,
        address tokenContract,
        uint256 amount
    ) public notContract returns (uint256, uint256) {
        IERC20 itoken = IERC20(address(tokenContract));
        require(amount > 0, "The value must be greater than 0");
        require(
            endTime > block.timestamp,
            "Time must be longer than the present"
        );
        uint256 allowance = itoken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        return _AddTokentoLockedPool(endTime, itoken, amount);
    }

    function _AddTokentoLockedPool(
        uint256 _endTime,
        IERC20 _itoken,
        uint256 _amount
    ) private returns (uint256, uint256) {
        address _Aitoken = address(_itoken);
        uint256 balancebefore = _itoken.balanceOf(address(this));
        _itoken.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 balanceafter = _itoken.balanceOf(address(this));
        _amount = balanceafter - balancebefore;

        if (!AllPairOfAddress[msg.sender][_Aitoken]) {
            NumberOfLockedAddress[msg.sender]++;
            LockedOfUser[msg.sender].push(_Aitoken);
            AllPairOfAddress[msg.sender][_Aitoken] = true;
            EachInfoLocked[msg.sender][_Aitoken] = InfoLocked(
                block.timestamp,
                _endTime,
                _amount,
                0,
                _itoken.decimals(),
                _itoken.name(),
                _itoken.symbol()
            );
        } else {
            //
            require(
                _endTime >= EachInfoLocked[msg.sender][_Aitoken].endTime,
                "Time must be After Ended Time"
            );
            EachInfoLocked[msg.sender][_Aitoken].amountLockedTokens =
                (EachInfoLocked[msg.sender][_Aitoken].amountLockedTokens) +
                _amount;
            EachInfoLocked[msg.sender][_Aitoken].endTime = _endTime;
            EachInfoLocked[msg.sender][_Aitoken].startTime = block.timestamp;
        }

        emit AddTokentoLockedPoolEvent(
            _Aitoken,
            msg.sender,
            block.timestamp,
            _endTime,
            _amount,
            _itoken.decimals(),
            _itoken.name(),
            _itoken.symbol()
        );
        return (_endTime, _amount);
    }

    function WithdrawTokenFreeOnTime(
        address tokenAddress,
        uint256 amount
    ) public notContract returns (address, uint256, bool) {
        require(amount > 0, "The value must be greater than 0");
        require(AllPairOfAddress[msg.sender][tokenAddress], "Locked Not Exist");
        require(
            EachInfoLocked[msg.sender][tokenAddress].amountFreeTokens >= amount,
            "Not Enough Free Token in Locked"
        );
        require(
            block.timestamp >= EachInfoLocked[msg.sender][tokenAddress].endTime,
            "Time is Not End"
        );
        return _WithdrawTokenFreeOnTime(tokenAddress, amount);
    }

    function _WithdrawTokenFreeOnTime(
        address _tokenAddress,
        uint256 _amount
    ) private returns (address, uint256, bool) {
        IERC20 itoken = IERC20(_tokenAddress);
        itoken.safeTransfer(msg.sender, _amount);
        EachInfoLocked[msg.sender][_tokenAddress].amountFreeTokens =
            (EachInfoLocked[msg.sender][_tokenAddress].amountFreeTokens) -
            _amount;
        emit WithdrawTokenofFree(
            _tokenAddress,
            msg.sender,
            _amount,
            block.timestamp,
            itoken.decimals(),
            itoken.name(),
            itoken.symbol()
        );
        return (_tokenAddress, _amount, true);
    }

    function MakeFreeTokens(
        address tokenCont,
        uint256 amount
    ) public returns (address, uint256) {
        require(amount > 0, "The value must be greater than 0");
        require(AllPairOfAddress[msg.sender][tokenCont], "Locked Not Exist");
        require(
            block.timestamp > EachInfoLocked[msg.sender][tokenCont].endTime,
            "Time is Not End"
        );
        require(
            EachInfoLocked[msg.sender][tokenCont].amountLockedTokens > 0,
            "Locked Pool is Zero Tokens"
        );
        require(
            amount <= EachInfoLocked[msg.sender][tokenCont].amountLockedTokens,
            "Must be less than the locked value"
        );
        return _MakeFreeTokens(tokenCont, amount);
    }

    function _MakeFreeTokens(
        address _tokenCont,
        uint256 _amount
    ) private returns (address, uint256) {
        EachInfoLocked[msg.sender][_tokenCont].amountFreeTokens =
            (EachInfoLocked[msg.sender][_tokenCont].amountFreeTokens) +
            _amount;
        EachInfoLocked[msg.sender][_tokenCont].amountLockedTokens =
            (EachInfoLocked[msg.sender][_tokenCont].amountLockedTokens) -
            _amount;

        IERC20 _itoken = IERC20(_tokenCont);

        emit MakeFreeTokensEvent(
            _tokenCont,
            msg.sender,
            _amount,
            block.timestamp,
            _itoken.decimals(),
            _itoken.name(),
            _itoken.symbol()
        );
        return (_tokenCont, _amount);
    }

    function HowMuchIsFreeOnLocked(
        address ownerLocked,
        address tokenContract
    ) public view returns (uint256) {
        return EachInfoLocked[ownerLocked][tokenContract].amountFreeTokens;
    }

    function HowMuchIsLockedOnLock(
        address ownerLocked,
        address tokenContract
    ) public view returns (uint256) {
        return EachInfoLocked[ownerLocked][tokenContract].amountLockedTokens;
    }

    function WhenIsEndedLocked(
        address ownerLocked,
        address tokenContract
    ) public view returns (uint256) {
        return EachInfoLocked[ownerLocked][tokenContract].endTime;
    }

    function StartLockedTime(
        address ownerLocked,
        address tokenContract
    ) public view returns (uint256) {
        return EachInfoLocked[ownerLocked][tokenContract].startTime;
    }

    function NameLockedPool(
        address ownerLocked,
        address tokenContract
    ) public view returns (string memory) {
        return EachInfoLocked[ownerLocked][tokenContract].nameToken;
    }

    function symbolLockedPool(
        address ownerLocked,
        address tokenContract
    ) public view returns (string memory) {
        return EachInfoLocked[ownerLocked][tokenContract].symbolToken;
    }

    function DecimalsLockedPool(
        address ownerLocked,
        address tokenContract
    ) public view returns (uint8) {
        return EachInfoLocked[ownerLocked][tokenContract].decimals;
    }

    function LockedPoolInfo(
        address ownerLocked,
        address tokenContract
    ) public view returns (InfoLocked memory) {
        return EachInfoLocked[ownerLocked][tokenContract];
    }

    function TokenisExist(
        address ownerLocked,
        address tokenContract
    ) public view returns (bool) {
        return AllPairOfAddress[ownerLocked][tokenContract];
    }

    function UserPools(
        address ownerLocked
    ) public view returns (address[] memory) {
        return LockedOfUser[ownerLocked];
    }
}
