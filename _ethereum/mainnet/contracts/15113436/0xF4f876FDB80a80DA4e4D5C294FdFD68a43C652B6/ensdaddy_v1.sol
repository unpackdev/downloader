// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ensdaddy_v1 is Ownable {
struct ensdata {
    uint256 id;
    string subdomain;
    string domain;
    string fulldomain; 
    address ownner;
    string status;
    uint256 price;
}
struct ensdomain {
    string domain;
    address ownner;
    bool active;
}

uint256 public mingas = 0.02 ether;   
bool public _saleIsActive = true;
mapping (uint256 => ensdata) public ensusers;
mapping (uint256 => ensdomain) public ensdomains; 
uint256 public ensdomains_count = 0;
uint256 public enssubdomains_count = 0; 

constructor(){}
    function domain_exist(string memory _domain) public view returns (bool) {
        for (uint i=0; i< ensdomains_count ; i++) {
            if(keccak256(bytes(ensdomains[i].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                return ensdomains[i].active;
            }  
        }
        return false;
    }

    function register_subdomain(string memory _domain, string memory _subdomain) external payable {
        require(
                 (_saleIsActive),
                "Minting is not Live"
        );
        require(
                 (msg.value >= mingas ),
                "Gas fee mismatch"
        );
        require(
                 ( domain_exist(_domain) ),
                "Domain does not exist"
        );
        string memory _fulldomain = string(abi.encodePacked(_subdomain, ".", _domain));
        require(
                 ( ! is_book(_fulldomain) ),
                "Subdomain already registered"
        );
        ensusers[enssubdomains_count] = ensdata(enssubdomains_count, _subdomain, _domain, _fulldomain, msg.sender, "Under process",msg.value);
        enssubdomains_count += 1;
        delete _fulldomain;
    }   

    function add_domains(string[] memory _domains, address _ownner) external onlyOwner  { 
        for (uint i=0; i< _domains.length; i++) {
            if(! domain_exist(_domains[i]) ){
                ensdomains[ensdomains_count] = ensdomain(_domains[i], _ownner, true) ;
                ensdomains_count += 1;
            }  
        }
    }

    function update_domain(bool status, string memory _domain, address _ownner) external onlyOwner {
        for (uint i=0; i< ensdomains_count; i++) {
            if(keccak256(bytes(ensdomains[i].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                ensdomains[i] = ensdomain(_domain, _ownner, status);
            }
        }    
    }

    function confirm_allsubdomain(string memory _domain) public {
        for (uint i=0; i< ensdomains_count; i++) {
            if(keccak256(bytes(ensdomains[i].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                for (uint256 j=0; j< enssubdomains_count; j++) {
                    if(keccak256(bytes(ensusers[j].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                     if(ensdomains[i].ownner == msg.sender ){
                           if(keccak256(bytes(ensusers[j].status)) == keccak256(bytes(string(abi.encodePacked("Under process")))) ){
                            ensusers[j].status =  "Registered";
                        }
                     }
                    }        
                }
            }
        }
    }

    function confirm_subdomain(string memory _domain, string memory _fulldomain) public {
        for (uint i=0; i< ensdomains_count; i++) {
            if(keccak256(bytes(ensdomains[i].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                if(ensdomains[i].ownner == msg.sender ){
                    for (uint256 j=0; j< enssubdomains_count; j++) {
                        if(keccak256(bytes(ensusers[j].fulldomain)) == keccak256(bytes(string(abi.encodePacked(_fulldomain)))) ){
                            ensusers[j].status =  "Registered";
                        }
                    }
                }
            }
        }
    }

    function denied_subdomain(string memory _domain, string memory _fulldomain) public {
        for (uint i=0; i< ensdomains_count; i++) {
            if(keccak256(bytes(ensdomains[i].domain)) == keccak256(bytes(string(abi.encodePacked(_domain)))) ){
                if(ensdomains[i].ownner == msg.sender ){
                    for (uint256 j=0; j< enssubdomains_count; j++) {
                        if(keccak256(bytes(ensusers[j].fulldomain)) == keccak256(bytes(string(abi.encodePacked(_fulldomain)))) ){
                            ensusers[j].status =  "Denied";
                        }
                    }
                }
            }
        }
    }
    
    function setMintLive(bool status) external onlyOwner {
		_saleIsActive = status;
	}

    function is_available(string memory _fulldomain) public view returns (string memory) {
        for (uint256 i=0; i< enssubdomains_count; i++) {
            if(keccak256(bytes(ensusers[i].fulldomain)) == keccak256(bytes(string(abi.encodePacked(_fulldomain)))) ){
                    return ensusers[i].status; 
            }
        }
        return "Available"; 
    }

    function is_book(string memory _fulldomain) internal view returns (bool) {
        for (uint256 i=0; i< enssubdomains_count; i++) {
            if(keccak256(bytes(ensusers[i].fulldomain)) == keccak256(bytes(string(abi.encodePacked(_fulldomain)))) ){
                    return true; 
            }
        }
        return false; 
    }

    function withdraw(uint256 amount, address toaddress) external onlyOwner {
      require(amount <= address(this).balance, "Amount > Balance");
      if(amount == 0){
          amount = address(this).balance;
      }
      payable(toaddress).transfer(amount);
    }
    
    function update_gas( uint256 _mingas) external onlyOwner {
        mingas = _mingas;
    }    
}