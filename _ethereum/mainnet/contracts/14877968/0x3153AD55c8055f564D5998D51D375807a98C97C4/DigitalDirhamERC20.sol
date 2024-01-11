// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Blacklistable.sol";
import "./Rescuable.sol";
import "./IERC677.sol";
import "./IERC677TransferReceiver.sol";
import "./IBurnableMintableERC677Token.sol";

/**
 * @title DigitalDirhamERC20
 * @dev ERC20 Token stablecoin
 */
contract DigitalDirhamERC20 is ERC20Upgradeable, IBurnableMintableERC677Token, ERC20PausableUpgradeable, Ownable, Blacklistable, Rescuable  {
    bytes4 internal constant ON_TOKEN_TRANSFER = 0xa4c0ed36; // onTokenTransfer(address,uint256,bytes)
    mapping (address => bool) public canMint;

    modifier onlyMinter() {
        require(canMint[msg.sender], "Caller can't mint");
        _;
    }

    function initialize() public initializer {
        __ERC20_init("DDstable", "DD");
        setOwner(msg.sender);
    }

    /**
     * @dev Default ERC20 transferFrom
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(sender)
        notBlacklisted(recipient)
        override
        returns (bool)
    {
        super.transferFrom(sender, recipient, amount);
        callAfterTransfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Default ERC20 transfer
     */
    function transfer(address recipient, uint256 value)
        public
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(recipient)
        returns (bool)
    {
        _transfer(_msgSender(), recipient, value);
        callAfterTransfer(_msgSender(), recipient, value);
        return true;
    }

    /**
   * ERC-677's only method implementation
   * See https://github.com/ethereum/EIPs/issues/677 for details
   */
    function transferAndCall(address recipient, uint256 value, bytes memory data) 
        external 
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(recipient)
        returns (bool) 
    {
        _transfer_no_event(_msgSender(), recipient, value);

        emit Transfer(_msgSender(), recipient, value, data);

        IERC677TransferReceiver receiver = IERC677TransferReceiver(recipient);
        // slither-disable-next-line unused-return
        receiver.onTokenTransfer(_msgSender(), value, data);
        return true;
    }

    function callAfterTransfer(address _from, address _to, uint256 _value) internal {
        if (canMint[_to]) {
            require(contractFallback(_from, _to, _value, new bytes(0)));
        }
    }

    function claimTokens(address _token, address _to) external override {
        revert();
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. 
     */
    function mint(address _to, uint256 _amount) public override whenNotPaused onlyMinter returns (bool){
        _mint(_to, _amount);
        return true;
    }

    function contractFallback(address _from, address _to, uint256 _value, bytes memory _data) private returns (bool) {
        //return _to.call(abi.encodeWithSelector(ON_TOKEN_TRANSFER, _from, _value, _data));
        IERC677TransferReceiver receiver = IERC677TransferReceiver(_to);
        receiver.onTokenTransfer(_from, _value, _data);
        return true;
    }  

    /**
     * @dev Minting function for bridge
     * @param user user address for whom deposit is being done 
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external {
        uint256 amount = abi.decode(depositData, (uint256));
        mint(user, amount);
    }

    /**
     * @dev Function to burn tokens from Owner wallet
     * @param amount The amount of tokens to burn. 
     */
    function burn(uint256 amount) public override whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Burning function for bridge
     * @param amount The amount of tokens to burn. 
     */
    function withdraw(uint256 amount) external { 
        burn(amount);
    }

    /**
     * @dev Pause contract. Restrict transfers and mint
     */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Setup trusted forwarder. Needed to use Biconomy
     * @param trustedForwarder The address of trusted forwarder
     */
    function setTrustedForwarder(address trustedForwarder) public whenNotPaused onlyOwner {
        _setTrustedForwarder(trustedForwarder);
    }

    /**
     * @dev This version is to keep track of BaseRelayRecipient
     */
    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
  
    function addMinter(address _address) public onlyOwner {
        require(!canMint[_address], "(addMinter) address is a already minter");
        canMint[_address] = true;
    }

    function removeMinter(address _address) public onlyOwner {
        require(canMint[_address], "(removeMinter) address is not a minter");
        canMint[_address] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}