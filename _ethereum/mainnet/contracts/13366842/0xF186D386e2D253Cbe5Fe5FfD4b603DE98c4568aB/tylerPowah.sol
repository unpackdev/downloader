pragma solidity ^0.8.0;


import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";


/**
 * @title TYLERPOWAH
 * @author DefiJesus
 *
 * An ERC20 token used for tracking the ownership count of fidenzas. This contract is 
 * inspired by SetProtocol's IndexPowah contract and  
 * Sushiswap's SUSHIPOWAH contract which serves the same purpose.
 */
contract TylerPowah is IERC20, Ownable {
    
    uint256 public min;
    uint256 public max;
    
    address public abAddress;
    
    
    /**
     *
     * @param _min  min Artblocks Range
     * @param _max  max ArtBlocks Range
     * @param _abAddress ArtBlocks SC address
     */
    constructor(
        uint256 _min,
        uint256 _max,
        address _abAddress
    )
        public
    {
        min = _min;
        max = _max;
        abAddress = _abAddress;
    }
    
    function configure(uint256 _min, uint256 _max, address _abAddress) public onlyOwner {
        min = _min;
        max = _max;
        abAddress = _abAddress;
    }
    

    /**
     * Computes an address's balance of fidenzas. Balances can not be transfered in the traditional way,
     * but are instead computed by the amount of ArtBlocks tokens that an account directly holds.
     *
     * @param _account  the address of the owner
     */
    function balanceOf(address _account) public view override returns (uint256) {

        uint256[] memory blocks = ArtBlocks(abAddress).tokensOfOwner(_account);
        uint256 counter = 0;
        
         for (uint256 i; i < blocks.length; i++) {
            if (blocks[i] >= min && blocks[i] <= max) {
                counter++;
            }
         }
        
        return counter;
    }


    /**
     * These functions are not used, but have been left in to keep the token ERC20 compliant
     */
    function name() public pure returns (string memory) { return "TYLERPOWAH"; }
    function symbol() public pure returns (string memory) { return "TYLERPOWAH"; }
    function decimals() public pure returns(uint8) { return 18; }
    function totalSupply() public view override returns (uint256) { return ArtBlocks(abAddress).totalSupply(); }
    function allowance(address, address) public view override returns (uint256) { return 0; }
    function transfer(address, uint256) public override returns (bool) { return false; }
    function approve(address, uint256) public override returns (bool) { return false; }
    function transferFrom(address, address, uint256) public override returns (bool) { return false; }
}

 interface ArtBlocks { 
   function tokensOfOwner(address owner) external view returns(uint256[] calldata); // No implementation, just the function signature. This is just so Solidity can work out how to call it.

    function totalSupply() external view returns (uint256);     
 }