// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ECDSA.sol";

import "./IBasicCoin.sol";
import "./IBasicStake.sol";

/// @custom:security-contact developer@heartx.art

contract BasicCoin is ERC20, ERC20Burnable, Ownable, IBasicCoin {
    // 1.[Types]: state variable
    mapping(address => recdBasicUnit) internal m_recdClaim;
    mapping(address => recdBasicUnit) internal m_recdSpend;

    // DAO Issues for setting fuctions
    address[3] public m_DAOList;
    mapping(address => uint256) public m_DAOTag; // DAO's address => 0/0x20/0x40, 0-reject, 0x20-approve "setOpSigner", 0x40-approve "setTreasury"
    mapping(uint256 => proposal) public m_fnTimeLock; // ST_OPSIGNER => proposal, means for proposal for "setOpSigner"

    uint256 public constant m_lockPeriod = 1 days; // locked peried, only DAO member can vote for proposal
    uint256 public constant m_lockExpire = 1 days; // operation expired time, need new proposal after that if no operation

    address internal m_OpSigner;
    address internal m_Treasury;

    uint256 public constant ST_OPSIGNER = 0x20;
    uint256 public constant ST_TREASURY = 0x40;

    constructor(
        string memory name,
        string memory symbol,
        address[3] memory vDAO
    ) ERC20(name, symbol) {
        m_OpSigner = msg.sender;
        m_Treasury = msg.sender;

        initDAO(vDAO);
    }

    function initDAO(address[3] memory vDAO) private {
        require(
            vDAO[0] != address(0) &&
                vDAO[1] != address(0) &&
                vDAO[2] != address(0),
            "DAO addresses couldn't be zero address, or couldn't be equal"
        );

        require(
            vDAO[0] != vDAO[1] && vDAO[1] != vDAO[2] && vDAO[0] != vDAO[2],
            "DAO addresses should be different"
        );

        require(
            vDAO[0] != msg.sender &&
                vDAO[1] != msg.sender &&
                vDAO[2] != msg.sender,
            "DAO addresses couldn't be the owner"
        );

        // DAO List & Tag
        m_DAOList = vDAO;
        m_DAOTag[vDAO[0]] = 0;
        m_DAOTag[vDAO[1]] = 0;
        m_DAOTag[vDAO[2]] = 0;

        // Function Timelock
        m_fnTimeLock[ST_OPSIGNER] = proposal({
            timeLock: 0,
            newAddress: address(0)
        });
        m_fnTimeLock[ST_TREASURY] = proposal({
            timeLock: 0,
            newAddress: address(0)
        });
    }

    function setPrivilegeTag(uint256 tagValue, address addrNewOP) external {
        require(
            msg.sender == m_DAOList[0] ||
                msg.sender == m_DAOList[1] ||
                msg.sender == m_DAOList[2],
            "address is not in DAO list"
        );
        require(
            tagValue == 0 || tagValue == ST_OPSIGNER || tagValue == ST_TREASURY,
            "invalid tagValue supplied"
        );

        // If want to approve the operation, must in AVL time-period
        uint256 curTime = block.timestamp;
        if (tagValue != 0) {
            // check the timelock is available
            require(
                curTime > m_fnTimeLock[tagValue].timeLock &&
                    curTime <= m_fnTimeLock[tagValue].timeLock + m_lockPeriod,
                "not in available time-period, setPrivilegeTag failed"
            );
            require(
                m_fnTimeLock[tagValue].newAddress == addrNewOP,
                "addrNewOP address not match the proposal"
            );
        }

        m_DAOTag[msg.sender] = tagValue;
    }

    function checkDAO(uint256 stType) private view {
        require(
            stType == ST_OPSIGNER || stType == ST_TREASURY,
            "invalid stType supplied"
        );
        // check the timelock is available
        require(
            block.timestamp > m_fnTimeLock[stType].timeLock + m_lockPeriod &&
                block.timestamp <=
                m_fnTimeLock[stType].timeLock + m_lockPeriod + m_lockExpire,
            "not in available time-period, checkDAO failed"
        );
        // check DAO Tag
        uint256 pass = 0;
        for (uint256 i = 0; i < 3; i++) {
            if (m_DAOTag[m_DAOList[i]] == stType) {
                pass++;
            }
        }
        require(pass >= 2, "DAO permission failed");
    }

    function initDAOTag() private {
        m_DAOTag[m_DAOList[0]] = 0;
        m_DAOTag[m_DAOList[1]] = 0;
        m_DAOTag[m_DAOList[2]] = 0;
    }

    function makeSetProposal(
        uint256 stType,
        address addrNewOP
    ) external onlyOwner {
        require(
            addrNewOP != address(0),
            "new operator address couldn't be zero"
        );
        require(
            stType == ST_OPSIGNER || stType == ST_TREASURY,
            "invalid stType supplied"
        );
        if (stType == ST_OPSIGNER) {
            require(m_OpSigner != addrNewOP, "new signer address required");
        } else {
            require(m_Treasury != addrNewOP, "new treasury address required");
        }
        // clear DAO tag
        initDAOTag();
        // update new proposal
        m_fnTimeLock[stType].timeLock = block.timestamp;
        m_fnTimeLock[stType].newAddress = addrNewOP;

        emit evProposal(stType, m_fnTimeLock[stType]);
    }

    // 2.[Funtions]: coin operation
    function _claimCoin(uint256 nonce, uint256 amount, uint256 tag) internal {
        // check the nonce
        require(
            m_recdClaim[msg.sender].nonce == nonce - 1,
            "wrong nonce, on claiming"
        );

        _transfer(address(this), msg.sender, amount);

        // update records
        m_recdClaim[msg.sender].nonce = nonce;
        m_recdClaim[msg.sender].amount.push(amount);
        m_recdClaim[msg.sender].tag.push(tag);

        // event
        emit evClaim(msg.sender, nonce, amount, tag);
    }

    function _spendCoin(uint256 nonce, uint256 amount, uint256 tag) internal {
        // check the nonce
        require(
            m_recdSpend[msg.sender].nonce == nonce - 1,
            "wrong nonce, on spending"
        );

        _transfer(msg.sender, m_Treasury, amount);

        // update records
        m_recdSpend[msg.sender].nonce = nonce;
        m_recdSpend[msg.sender].amount.push(amount);
        m_recdSpend[msg.sender].tag.push(tag);

        // event
        emit evSpend(msg.sender, nonce, amount, tag);
    }

    function _stakeCoin(
        IBasicStake conStake,
        address addrStaker,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount
    ) internal {
        require(conStake != IBasicStake(address(0)), "stake contract not set");

        uint256 deltaT = 300; // 5 minutes, for time-adjusting
        uint256 sum = 0;
        uint256 preTime = 0;

        for (uint256 i = 0; i < aryTime.length; i++) {
            // block timestamp must smaller than the locked time
            require(
                block.timestamp < (aryTime[i] + deltaT),
                "locked time expired"
            );
            require(
                aryTime[i] > preTime,
                "aryTime elements should be in ascending order[C]"
            );
            require(aryAmount[i] > 0, "aryAmount elements can not be zero");
            preTime = aryTime[i];
        }
        for (uint256 i = 0; i < aryAmount.length; i++) {
            sum += aryAmount[i];
        }

        // checking the balance for staking
        require(
            balanceOf(address(this)) >= sum,
            "no sufficient tokens for staking"
        );

        conStake.applyStake(addrStaker, nonce, aryTime, aryAmount);
        _transfer(address(this), address(conStake), sum);
    }

    // 3.[Functions]: verification
    function _verifyBasicSingleData(
        address addrToken,
        address addrUser,
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes4 selector,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 orderHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    addrToken,
                    tag,
                    amount,
                    nonce,
                    addrUser,
                    selector,
                    block.chainid
                )
            )
        );
        address signer = ECDSA.recover(orderHash, signature);
        return (signer == m_OpSigner);
    }

    // 2.2 Verify signature for staking:
    function _verifyBasicArrayData(
        address addrToken,
        address addrCont,
        address addrUser,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount,
        bytes4 selector,
        bytes memory signature
    ) internal view returns (bool) {
        require(
            aryTime.length == aryAmount.length,
            "timestamp and amount array length should be equal"
        );
        require(aryTime.length <= 10, "no more 10 arrays");

        // check signature
        bytes32 orderHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    addrToken,
                    addrCont,
                    addrUser,
                    nonce,
                    aryTime,
                    aryAmount,
                    selector,
                    block.chainid
                )
            )
        );
        address signer = ECDSA.recover(orderHash, signature);
        return (signer == m_OpSigner);
    }

    // 4.[Functions]: setting
    function setOpSigner(address addr) external onlyOwner {
        require(
            addr != address(0) && addr != m_OpSigner,
            "invalid address, on signer setting"
        );

        checkDAO(ST_OPSIGNER);

        address addrOld = m_OpSigner;
        m_OpSigner = addr;

        // recover DAOTag
        initDAOTag();

        emit evSetup(addrOld, m_OpSigner, ST_OPSIGNER);
    }

    function setTreasury(address addr) external onlyOwner {
        require(
            addr != address(0) && addr != m_Treasury,
            "invalid address, on treasury setting"
        );

        checkDAO(ST_TREASURY);

        address addrOld = m_Treasury;
        m_Treasury = addr;

        // recover DAOTag
        initDAOTag();

        emit evSetup(addrOld, m_Treasury, ST_TREASURY);
    }

    // 5.[Functions]: view
    function viewClaimHist(
        address addr
    ) external view returns (recdBasicUnit memory) {
        return m_recdClaim[addr];
    }

    function viewSpendHist(
        address addr
    ) external view returns (recdBasicUnit memory) {
        return m_recdSpend[addr];
    }

    function viewDAOInfo()
        external
        view
        returns (
            uint256,
            uint256,
            address[3] memory,
            uint256[3] memory,
            proposal memory,
            proposal memory
        )
    {
        return (
            m_lockPeriod,
            m_lockExpire,
            m_DAOList,
            [
                m_DAOTag[m_DAOList[0]],
                m_DAOTag[m_DAOList[1]],
                m_DAOTag[m_DAOList[2]]
            ],
            m_fnTimeLock[ST_OPSIGNER],
            m_fnTimeLock[ST_TREASURY]
        );
    }
}
