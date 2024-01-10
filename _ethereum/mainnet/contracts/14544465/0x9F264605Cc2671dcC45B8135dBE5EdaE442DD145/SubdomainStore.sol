// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ENS.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

/**
 * @dev A basic interface for ENS resolvers.
 */
interface Resolver {
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
  function addr(bytes32 node) external view returns (address);
  function setAddr(bytes32 node, address addr) external;
  function setText(bytes32 node, string calldata key, string calldata value) external;
  function setContenthash(bytes32 node, bytes calldata hash) external;
  function setAddr(bytes32 node, uint coinType, bytes memory a) external;
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract SubdomainStore is IERC721Receiver, Ownable, ApproveAndCallFallBack {

  struct Domain {
    string name;
    uint price;
  }

  //.eth
  bytes32 constant internal TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

  //0xbitcoin contract
  address internal xbtc = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

  //0xbitcoin miners guild contract
  address internal guild = 0x167152A46E8616D4a6892A6AfD8E52F060151C70;

  //ens registry
  ENS internal ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  //funds trackers
  uint256 internal devFunds = 0;
  uint256 internal guildFunds = 0;

  //share %
  uint256 internal devShare = 25;
  uint256 internal guildShare = 75;
  
  mapping (bytes32 => Domain) internal domains;
  
  constructor() {
    
  }
  
  /**
   * @dev Configures a domain for sale.
   * @param name The name to configure.
   * @param price The price in wei to charge for subdomain registrations
   */
  function configureDomain(string memory name, uint price) public onlyOwner {
    bytes32 label = keccak256(bytes(name));
    Domain storage domain = domains[label];

    if (keccak256(abi.encodePacked(domain.name)) != label) {
      // New listing
      domain.name = name;
    }

    domain.price = price;
  }

  function setShares(uint256 _devShare, uint256 _guildShare) external onlyOwner {
    require(_devShare+_guildShare==100 && _devShare >= 0 && _guildShare >= 0, "Invalid share values");
    devShare = _devShare;
    guildShare = _guildShare;
  }

  //Sets the address record for a resident ENS name
  function setResidentAddress(string calldata name, address addr, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setAddr(domainNode, addr);
  }

  //Sets the address record for a resident ENS name
  function setResidentAddress(string calldata name, uint coinType, bytes memory a, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setAddr(domainNode, coinType, a);
  }

  //Sets the text record for a resident ENS name
  function setResidentText(string calldata name, string calldata key, string calldata value, Resolver resolver) external onlyOwner{ 
    bytes32 label = keccak256(bytes(name)); 
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setText(domainNode, key, value);
  }

  //Sets the content record for a resident ENS name
  function setResidentContenthash(string calldata name, bytes calldata hash, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setContenthash(domainNode, hash);
  }
  
  //Sets the resolver record for a resident ENS name
  function setResidentResolver(string calldata name, address resolver) external onlyOwner {
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    ens.setResolver(domainNode, resolver);
  }
  
  function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
    // Get the subdomain so we can configure it
    ens.setSubnodeOwner(node, label, address(this));

    bytes32 subnode = keccak256(abi.encodePacked(node, label));
    // Set the subdomain's resolver
    ens.setResolver(subnode, address(resolver));

    // Set the address record on the resolver
    resolver.setAddr(subnode, subdomainOwner);

    // Pass ownership of the new subdomain to the registrant
    ens.setOwner(subnode, subdomainOwner);    
  }

  /**
   * @dev Registers a subdomain.
   * @param label The label hash of the domain to register a subdomain of.
   * @param subdomain The desired subdomain label.
   * @param subdomainOwner The account that should own the newly configured subdomain.
   */
  function register(bytes32 label, string memory subdomain, address subdomainOwner, address resolver) public {
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));

    bytes32 subdomainLabel = keccak256(bytes(subdomain));

    // Subdomain must not be registered already.
    require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0), "Subdomain must not be registered already");
    Domain storage domain = domains[label];

    // Domain must be available for registration
    require(keccak256(abi.encodePacked(domain.name)) == label, "Domain must be available for registration");

    // The account that gets the subdomain also needs to pay
    require(IERC20(xbtc).transferFrom(subdomainOwner, address(this), domain.price), "User must have paid");

    devFunds = devFunds + (domain.price * devShare / 100);
    guildFunds = guildFunds + (domain.price * guildShare / 100);

    doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function receiveApproval(address from, uint256, address token, bytes memory data) public override {
    require(token == xbtc, "Must pay in 0xBTC");

    bytes32 label; 
    string memory subdomain;
    address resolver;

    (label, subdomain, resolver) = abi.decode(data, (bytes32, string, address));

    register(label, subdomain, from, resolver);
  }

  function withdrawAndShare() public virtual {
    require(devFunds > 0 || guildFunds > 0 ,'nothing to withdraw');

    //prevent reentrancy
    uint256 devFee = devFunds;
    devFunds = 0;

    uint256 guildFee = guildFunds;
    guildFunds = 0;

    require(IERC20(xbtc).transfer(fappablo, devFee/2),'transfer failed');
    require(IERC20(xbtc).transfer(rms, devFee/2),'transfer failed');
    require(IERC20(xbtc).transfer(guild, guildFee),'transfer failed');
  }

  //Helper function to encode the data needed for ApproveAndCall
  function encodeData(bytes32 label, string calldata subdomain, address resolver) external pure returns (bytes memory data) {
    return abi.encode(label, subdomain, resolver);
  }

  //Helper function to get the label hash
  function encodeLabel(string calldata label) external pure returns (bytes32 encodedLabel) {
    return keccak256(bytes(label));
  }

  function getPrice (bytes32 label) external view returns (uint256 price){
    Domain storage data = domains[label];
    return data.price;
  }

}
