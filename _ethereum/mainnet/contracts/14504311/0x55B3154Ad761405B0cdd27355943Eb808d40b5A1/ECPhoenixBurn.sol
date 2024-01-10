//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.7;

/***
 *            ███████ ████████ ██   ██ ███████ ██████      ██████  █████  ██████  ██████  ███████      
 *            ██         ██    ██   ██ ██      ██   ██    ██      ██   ██ ██   ██ ██   ██ ██           
 *            █████      ██    ███████ █████   ██████     ██      ███████ ██████  ██   ██ ███████      
 *            ██         ██    ██   ██ ██      ██   ██    ██      ██   ██ ██   ██ ██   ██      ██      
 *            ███████    ██    ██   ██ ███████ ██   ██ ██  ██████ ██   ██ ██   ██ ██████  ███████      
 *                                                                                                     
 *                                                                                                     
 *        ██████  ██   ██  ██████  ███████ ███    ██ ██ ██   ██     ██████  ██    ██ ██████  ███    ██ 
 *        ██   ██ ██   ██ ██    ██ ██      ████   ██ ██  ██ ██      ██   ██ ██    ██ ██   ██ ████   ██ 
 *        ██████  ███████ ██    ██ █████   ██ ██  ██ ██   ███       ██████  ██    ██ ██████  ██ ██  ██ 
 *        ██      ██   ██ ██    ██ ██      ██  ██ ██ ██  ██ ██      ██   ██ ██    ██ ██   ██ ██  ██ ██ 
 *        ██      ██   ██  ██████  ███████ ██   ████ ██ ██   ██     ██████   ██████  ██   ██ ██   ████ 
 *                                                                                                     
 *    ETHER.CARDS - PHOENIX BURN
 *
 */

import "./Ownable.sol";
import "./EnumerableSet.sol";

interface ITraitRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function traits(uint16 traitID) external view returns (string memory, address, uint8, uint16, uint16);
}

interface IERC721 {
    function ownerOf(uint256) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}


contract ECPhoenixBurn is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractController;

    IERC721             public erc721;      // Ether Cards
    ITraitRegistry      public registry;    // Trait registry
    bool                public locked       = false;
    uint256             public startTime    = 1648771200;  // Fri Apr 01 2022 00:00:00 GMT+0000
    uint256             public endTime      = 1651363200;  // Sun May 01 2022 00:00:00 GMT+0000
    uint16              public burnCount    = 0;
    uint16              public maxCount     = 1945;
    uint16              public PhoenixTraitId = 42;

    event contractControllerEvent(address _address, bool mode);

    constructor(
        address _erc721,
        address _registry
    ) {
        erc721 = IERC721(_erc721);
        registry = ITraitRegistry(_registry);
    }

    receive() external payable {}

    function amount() public virtual pure returns(uint256) {
        return 0.2 ether;
    }

    function burn(uint16[] memory tokenId) public {

        require(!locked, "ECPhoenixBurn: contract locked.");
        require(tokenId.length > 0, "ECPhoenixBurn: at least 1 token.");
        require(address(this).balance > tokenId.length * amount(), "ECPhoenixBurn: not enough funds.");
        require(getTimestamp() > startTime, "ECPhoenixBurn: before start time.");
        require(getTimestamp() < endTime, "ECPhoenixBurn: after end time.");

        // Phoenix is a type 2 - range with inverted values, outside range actual values
        // Load trait ranges
        (,,,uint16 _start, uint16 _end) = registry.traits(PhoenixTraitId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];

            require(erc721.ownerOf(currentTokenId) == msg.sender, "ECPhoenixBurn: not owner of token.");
            require(registry.hasTrait(PhoenixTraitId, currentTokenId), "ECPhoenixBurn: trait not found on token.");

            // inverted values for everything
            // need to send true to disable
            bool traitOffValue = true;
            // if token in range, flip value
            if(_start <= currentTokenId && currentTokenId <= _end) {
                traitOffValue = !traitOffValue;
            }

            registry.setTrait(PhoenixTraitId, currentTokenId, traitOffValue);
        }

        uint256 _amount = tokenId.length * amount();
        burnCount += uint16(tokenId.length);
        (bool sent, ) = msg.sender.call{value: _amount}(""); // don't use send or xfer (gas)
        require(sent, "ECPhoenixBurn: failed to send ether.");
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    struct contractInfo {
        address erc721;
        address registry;
        bool    locked;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 burnCount;
        uint256 maxCount;
        uint256 PhoenixTraitId;
        uint256 contractBalance;
        bool    claimAvailable;
    }

    function tellEverything() external view returns (contractInfo memory) {
        return contractInfo(
            address(erc721),
            address(registry),
            locked,
            startTime,
            endTime,
            amount(),
            burnCount,
            maxCount,
            PhoenixTraitId,
            address(this).balance,
            (getTimestamp() >= startTime && getTimestamp() <= endTime && !locked )
        );
    }

    /*
    *   Admin Stuff
    */

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    function toggleLock() public onlyAllowed {
        locked = !locked;
    }

    // blackhole prevention methods
    function drain() external onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}(""); // don't use send or xfer (gas)
        require(sent, "ECPhoenixBurn: failed to send ether");
    }

    function retrieveERC20(address _tracker, uint256 _amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, _amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "ECPhoenixBurn: Not Authorised"
        );
        _;
    }

}
