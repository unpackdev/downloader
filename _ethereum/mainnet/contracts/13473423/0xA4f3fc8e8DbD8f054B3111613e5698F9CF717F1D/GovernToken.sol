// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract GovernToken is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    using SafeMath for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURN_ROLE");
    uint public mStartBlock;
    uint constant public SubsidyHalvingInterval = 3600*24*365/15; 
    uint constant public InitialTokenPerBlock = 5 * 1e18; // 

    uint[64] public mCaps;
    uint[64] public mSubsides;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol, uint startBlock, uint[64] memory caps, uint[64] memory subsides ) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // _setupRole(MINTER_ROLE, _msgSender());
        // _setupRole(PAUSER_ROLE, _msgSender());
        // _setupRole(BURNER_ROLE, _msgSender());

        mStartBlock = startBlock;
        _setCaps( caps, subsides );
       // _initCaps();
    }


    function _setCaps( uint[64] memory caps, uint[64] memory subsides ) internal {
        mCaps = caps;
        mSubsides = subsides;
    }

    // function _initCaps() internal {
    //     uint amount = 0;
    //     uint gen = InitialTokenPerBlock;
    //     mCaps[0] = 0;
    //     mSubsides[0] = gen;
    //     for( uint i = 1; i < 64; ++i ){
    //         amount = amount.add( gen.mul( SubsidyHalvingInterval ) );
    //         gen = gen.div(2);

    //         mCaps[i] = amount;
    //         mSubsides[i] = gen;
    //     }
    // }


    // 总数为2100万，最初产量300, 每一年（SubsidyHalvingInterval块）减半
    // total cap is 21 Million, the initial supply per block is 300, halving per year ( haalving per  SubsidyHalvingInterval blocks )
    function cap( uint blockNumb ) public view returns( uint amount ){
        if( blockNumb <= mStartBlock ){
            return 0;
        }
        uint runBlock = blockNumb.sub(mStartBlock);
        uint i =  runBlock.div(SubsidyHalvingInterval);
        if( i < 64 ){
            amount = mCaps[i];
            amount = amount.add( mSubsides[i].mul( runBlock.mod( SubsidyHalvingInterval ) ));
        }else{
            amount = mCaps[63];            
        }
    }


    function supplyPerBlock( uint blockNumb ) public view returns( uint amount ){
        if( blockNumb <= mStartBlock ){
            return 0;
        }
        uint runBlock = blockNumb.sub(mStartBlock);
        uint i =  runBlock.div(SubsidyHalvingInterval);
        if( i < 64 ){
            amount = mSubsides[i];
        }else{
            amount = 0;            
        }
    }


    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint amount ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        uint c = cap( block.number );
        require( c >= totalSupply().add( amount ) );
        _mint(to, amount );
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFromRole(address account, uint256 amount) public virtual  {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burn role to burn");
        _burn(account, amount);
    }

}
