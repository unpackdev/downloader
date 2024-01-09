// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SacredCoin.sol";


contract GratitudeCoin is ERC20, Ownable, SacredCoin {

    string private gratitudeStatement;

    constructor() ERC20("GratitudeCoin", "GRTFUL") {
        _mint(msg.sender, 1000000 * 10 ** decimals());

        /**
        * @dev calling the setGuideline function to create 1 guideline:
        */
        setGuideline("Think of something to be grateful for.", "Every time you buy, sell or otherwise use the coin, take a second to think of something that you are grateful for. It could be your family, your friends, the neighborhood you are living in or your pet tortoise. Ideally, you should think about something different that you're grateful for every time you use the coin.");
    }

    address private crowdsaleAddress;

    event GratitudeEvent(string gratitudeStatment);

    function crowdsale() public view returns(address) {
        return(crowdsaleAddress);
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        crowdsaleAddress = _crowdsaleAddress;
    }

    modifier onlyCrowdsale() {
        require( _msgSender() == crowdsaleAddress, "only the crowdsale contract can call this function externally");
        _;
    }

    function emitGratitudeEventSimpleFromCrowdsale(address buyerAddress) public onlyCrowdsale {
        string memory _buyerAddressString = addressToString(buyerAddress);
        gratitudeEventSimple(_buyerAddressString);
    }

    function emitGratitudeEventPersonalizedFromCrowdsale(string memory name, string memory gratitudeObject) public onlyCrowdsale {
        gratitudeEventPersonalized(name, gratitudeObject);
    }

    /**
    @dev Created a special transfer function that can only be called from the crowdsale contract, in order to allow for
    said contract to manage the gratitude events emitted.
    */
    function transferFromCrowdsale(address recipient, uint256 amount) public virtual onlyCrowdsale returns (bool) {
        super.transfer(recipient, amount);
        return true;
    }

    function gratitudeEventSimple(string memory _address) private {
        emit GratitudeEvent(string(abi.encodePacked(_address, " is thinking about something that they're grateful for (see Gratitude Coin's guidelines for details)")));
    }

    function gratitudeEventPersonalized(string memory name, string memory gratitudeObject) private {
        emit GratitudeEvent(string(abi.encodePacked(name, " is grateful for ", gratitudeObject)));
    }

    function transferGrateful(address to, uint tokens, string memory name, string memory gratitudeObject) public {
        super.transfer(to, tokens);
        gratitudeEventPersonalized(name, gratitudeObject);
    }

    /**
    * @dev function that converts an address into a string
    * NOTE: this function returns all lowercase letters. Ethereum addresses are not case sensitive.
    * However, because of this the address won't pass the optional checksum validation.
    */
    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    /**
    * @dev uses the same transfer function as the openzeppelin account, but also emits the GratitudeEvent event.
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        super.transfer(recipient, amount);
        string memory _senderString = addressToString(msg.sender);
        gratitudeEventSimple(_senderString);
        return true;
    }
}