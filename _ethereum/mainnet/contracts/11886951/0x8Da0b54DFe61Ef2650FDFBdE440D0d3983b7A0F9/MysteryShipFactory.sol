// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./IFactoryERC721.sol";
import "./MysteryShip.sol";
import "./ProxyRegistry.sol";

contract MysteryShipFactory is FactoryERC721, Ownable {
    event MintRequested(address from, bytes32 requestId);
    event MintDone(bytes32 requestId, uint256 randomness, uint256 index, uint256 model);

    event Transfer(
      address indexed from,
      address indexed to,
      uint256 indexed tokenId
    );

    string private baseURI = "https://mysterybox.service.cometh.io/0";

    uint256 constant NUMBER_OF_SHIPS_PER_BUNDLE = 3;

    mapping(bytes32 => address) requestedMints; 
    uint256 requestedMintsCount; 

    uint8[] private availableModels;

    MysteryShip public mysteryShip;
    ProxyRegistry private proxyRegistry;

    constructor(address _mysteryShip, address _proxyRegistry) public
    {
        mysteryShip = MysteryShip(_mysteryShip);
        proxyRegistry = ProxyRegistry(_proxyRegistry);

        emit Transfer(address(0), owner(), 0);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        emit Transfer(_prevOwner, newOwner, 0);
    }


    function name() override external view returns (string memory) {
        return "MysteryShipFactory";
    }

    function symbol() override external view returns (string memory) {
        return "MSF";
    }

    function supportsFactoryInterface() override public view returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return 1;
    }

    function remainingsBoxes() external view returns (uint256) {
      return availableModels.length;
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
      require(_optionId == 0, 'optionId must be zero');
      return mysteryShip.supply() >= NUMBER_OF_SHIPS_PER_BUNDLE;
    }

    function tokenURI(uint256) override external view returns (string memory) {
      return baseURI;
    }

    function mint(uint256 optionId, address from) override public {
      assert(
        address(proxyRegistry.proxies(owner())) == msg.sender ||
        owner() == msg.sender
      );
      require(canMint(optionId), '');

       for (uint256 i = 0; i < NUMBER_OF_SHIPS_PER_BUNDLE; i++) {
         mysteryShip.mint(from);
       }
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
