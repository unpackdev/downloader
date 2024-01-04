// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";

import "./INestPool.sol";
import "./INTokenController.sol";
import "./INToken.sol";
import "./NToken.sol";

// import "./NestMining.sol";
// import "./INNRewardPool.sol";

/// @title NTokenController
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

contract NTokenController is INTokenController, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ============== */

    /// @dev A number counter for generating ntoken name
    uint32  public ntokenCounter;
    uint8   public flag;         // 0: uninitialized | 1: active | 2: shutdown
    uint216 private _reserved;

    uint8   constant NTCTRL_FLAG_UNINITIALIZED    = 0;
    uint8   constant NTCTRL_FLAG_ACTIVE           = 1;
    uint8   constant NTCTRL_FLAG_PAUSED           = 2;

    /// @dev A mapping for all auctions
    ///     token(address) => NTokenTag
    mapping(address => NTokenTag) private nTokenTagList;

    /* ========== PARAMETERS ============== */

    uint256 public openFeeNestAmount = 10_000; // default = 10_000

    /* ========== ADDRESSES ============== */

    /// @dev Contract address of NestPool
    address public C_NestPool;
    /// @dev Contract address of NestToken
    address public C_NestToken;
    /// @dev Contract address of NestDAO
    address public C_NestDAO;

    address private governance;

    /* ========== EVENTS ============== */

    /// @notice when the auction of a token gets started
    /// @param token    The address of the (ERC20) token
    /// @param ntoken   The address of the ntoken w.r.t. token for incentives
    /// @param owner    The address of miner who opened the oracle
    event NTokenOpened(address token, address ntoken, address owner);
    event NTokenDisabled(address token);
    event NTokenEnabled(address token);

    /* ========== CONSTRUCTOR ========== */

    constructor(address NestPool) public
    {
        governance = msg.sender;
        flag = NTCTRL_FLAG_UNINITIALIZED;
        C_NestPool = NestPool;
    }

    /// @dev The initialization function takes `_ntokenCounter` as argument, 
    ///     which shall be migrated from Nest v3.0
    function start(uint32 _ntokenCounter) public onlyGovernance
    {
        require(flag == NTCTRL_FLAG_UNINITIALIZED, "Nest:NTC:!flag");
        ntokenCounter = _ntokenCounter;
        flag = NTCTRL_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));
    }

    modifier noContract()
    {
        require(address(msg.sender) == address(tx.origin), "Nest:NTC:^(contract)");
        _;
    }

    modifier whenActive() 
    {
        require(flag == NTCTRL_FLAG_ACTIVE, "Nest:NTC:!flag");
        _;
    }

    modifier onlyGovOrBy(address _account)
    {
        if (msg.sender != governance) { 
            require(msg.sender == _account,
                "Nest:NTC:!Auth");
        }
        _;
    }

    /* ========== GOVERNANCE ========== */

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:NTC:!governance");
        _;
    }

    function loadGovernance() override external
    {
        governance = INestPool(C_NestPool).governance();
    }

    /// @dev  It should be called immediately after the depolyment
    function loadContracts() override external onlyGovOrBy(C_NestPool) 
    {
        C_NestToken = INestPool(C_NestPool).addrOfNestToken();
        C_NestDAO = INestPool(C_NestPool).addrOfNestDAO();
    }
    
    function setParams(uint256 _openFeeNestAmount) override external onlyGovernance
    {
        emit ParamsSetup(address(msg.sender), openFeeNestAmount, _openFeeNestAmount);
        openFeeNestAmount = _openFeeNestAmount;
    }

    /// @dev  Bad tokens should be banned 
    function disable(address token) external onlyGovernance
    {
        NTokenTag storage _to = nTokenTagList[token];
        _to.state = 1;
        emit NTokenDisabled(token);
    }

    function enable(address token) external onlyGovernance
    {
        NTokenTag storage _to = nTokenTagList[token];
        _to.state = 0;
        emit NTokenEnabled(token);
    }

    /// @dev Stop service for emergency
    function pause() external onlyGovernance
    {
        require(flag == NTCTRL_FLAG_ACTIVE, "Nest:NTC:!flag");
        flag = NTCTRL_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() external onlyGovernance
    {
        require(flag == NTCTRL_FLAG_PAUSED, "Nest:NTC:!flag");
        flag = NTCTRL_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));
    }

    /* ========== OPEN ========== */

    /// @notice  Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev  Create and map the (Token, NToken) pair in NestPool
    /// @param token  The address of token contract
    function open(address token) override external noContract whenActive
    {
        require(INestPool(C_NestPool).getNTokenFromToken(token) == address(0x0),
            "Nest:NTC:EX(token)");
        require(nTokenTagList[token].state == 0,
            "Nest:NTC:DIS(token)");

        nTokenTagList[token] = NTokenTag(
            address(msg.sender),                                // owner
            uint128(0),                                         // nestFee
            uint64(block.timestamp),                            // startTime
            0,                                                  // state
            0                                                   // _reserved
        );
        
        //  create ntoken
        NToken ntoken = new NToken(strConcat("NToken",
                getAddressStr(ntokenCounter)),
                strConcat("N", getAddressStr(ntokenCounter)),
                address(governance),
                // NOTE: here `bidder`, we use `C_NestPool` to separate new NTokens 
                //   from old ones, whose bidders are the miners creating NTokens
                address(C_NestPool)
        );

        // increase the counter
        ntokenCounter = ntokenCounter + 1;  // safe math
        INestPool(C_NestPool).setNTokenToToken(token, address(ntoken));

        // is token valid ?
        ERC20 tokenERC20 = ERC20(token);
        tokenERC20.safeTransferFrom(address(msg.sender), address(this), 1);
        require(tokenERC20.balanceOf(address(this)) >= 1, 
            "Nest:NTC:!TEST(token)");
        tokenERC20.safeTransfer(address(msg.sender), 1);

        // charge nest
        ERC20(C_NestToken).transferFrom(address(msg.sender), address(C_NestDAO), openFeeNestAmount);

        // raise an event
        emit NTokenOpened(token, address(ntoken), address(msg.sender));

    }

    /* ========== VIEWS ========== */

    function NTokenTagOf(address token) override public view returns (NTokenTag memory) 
    {
        return nTokenTagList[token];
    }

    /* ========== HELPERS ========== */

    /// @dev from NESTv3.0
    function strConcat(string memory _a, string memory _b) public pure returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        } 
        return string(ret);
    } 
    
    /// @dev Convert a 4-digital number into a string, from NestV3.0
    function getAddressStr(uint256 iv) public pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint256 index = 0;
        do {
            buf[index++] = byte(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0 || index < 4);
        bytes memory str = new bytes(index);
        for(uint256 i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }

}