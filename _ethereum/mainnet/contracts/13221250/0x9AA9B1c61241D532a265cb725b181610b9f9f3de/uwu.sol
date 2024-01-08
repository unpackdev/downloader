// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC721.sol";


/*
                  &(,    @%(,.                   @%(,.    &(*                   
     (%/,        @%(/,   @((*,       @#(*.       @%((,,  @%(/*        &#*,      
     @#(*.       @%(/*   @%((..     @&(((,.     @&((/*   @%(*.       @&(/,      
      @#(/.,, *&&#(//     @&(((///((((((((((//(((((((     @%(/.,, .&&#((//      
       @@%(((((((#%%         @@&%#%%&&   @@&%#%%&&&        @@&((((((((#%        
            %@(                                                 ,@@             
                     (/          ,       #(.     ,     .    ,                   
                 /&(%@@@%/   @((&@&   @##  @/,  &&,. @&*.  @(/                  
                 @%.         @**      @//%&&#    /&,/(#%&,#(/                   
                  @&(/(##(   @/*       @#*(##(    .@#/  @@((                    
                                                                                
                                                              
                             ,@     .(                                          
                         & ,@@#  (@@@@ ,( ,.       %#                           
                           @  ,,.@,                   @,                        
                       @  .,/                             @                     
                     (  .             @                 ,    #                  
                   @,  .   *         %                    @    %                
                 ,,,@     @              ,                 &    ,               
                *,,,     .        @   , .    @              %   ,,@             
                %,,&    ,/  #     ,@. , .    (@         &   @   *,,@            
               *,,,,    ,,  @     *.@  ...   @.#, &     /   *  ,,,,,            
              @,,,,,@   ,@@       @.../, &   *...@,* @  @  @, .,&,,,@           
              *,/.,,,&  ,@*& ((    .....,*(   *...#@ @ @, %&, ,,@,,,@           
              ,,@,@ ,,.@ ,@  @  @  @......@.@.%,.@.@@,@@@@,,,,,@,,,,@           
              ,,&,,,  .,@(. &(  @  @@.........#&@#  *   @@#,,,@,,,,,*           
             .,,/,,,  ,.#   (#&%(. ............ ##(##@  .%,(,@*@,,,,            
             .,,,,,,. @,,..@,%(#@ ............. ((# #  (@,,,,,%@.%,#            
             *,..#,.,%..,,,.........................,,,,,,,@,,@.@&,@            
             #,,@@, .,@%.............................,,,,..,,,*..*,@            
             @,,&&,  .(@..................................@, ..@,,,*            
             @,,#(.   /#@.............,/,..................  @,,,,,.            
            @@ @#(    &##@......./////&@@@&////@.........@   %,,,,,             
           ##, ###(.  &###@.......@/@/****(@////........@&   ,,,,@,/            
          @*# &###@.  @#####@........@******@.........@%# &  ,@,,/,,@           
         @,#@ ####&   @&#####%(/.................../###@@.  &,#@,,%*,*          
        %,##@ #####,  #&########@,@.............@######@/*  @(#@,,*@*,,&        
       ,,/#.# @###&%   (########@,,,,,,#@@@,,,,&#######@    @###(,,@ #,,/       
     @,,,#  .*  ##(&,   %###@##@@,,,,,,,,,,,,,,&&@@####%..  %####,,,@  &, *     
    @,,,&  # ,,@ .##@*   @&&&&&&,,,,,,,,,,,,,,,@@&&&&&&  ,% @#####,, @     @    
   ,,,,@  @  ,,*#(@ @(,@  .&&&@,,,,,,,,,,,,,,,,,@&&&&&&  , (@&&&&&@*  @   * ,   
 @,,,,   @*@&&&&&&&&.,@,,,&  @,,,,,,,,,,,...,,@&&&&&&&@@ (, @@ &@ @&@  @    &, 
*/


contract UWUGold is ERC20, Pausable, Ownable {
    
    address uwuContract;
    mapping(uint256 => bool) private _claims;
    uint256 private _claimable;
    
    event Claimed(address indexed owner, uint256 indexed tokenId, uint256 indexed amount);
    
    constructor(address uwuContract_, uint256 amount_) ERC20("UWU Gold", "UWUG") {
        require(uwuContract_ != address(0), "UWUGold: address is null");
        _mint(_msgSender(), 10**23);
        uwuContract = uwuContract_;
        _claimable = amount_;
        _pause();
    }
    
    function claimed(uint256 tokenId_) public view returns (bool){
        return _claims[tokenId_];
    }
    
    function claim(uint256 tokenId_) public whenNotPaused returns (bool) {
        require(totalSupply() < ((_claimable * 9670) + 10**23), "UWUGold: Max supply reached");
        require(IERC721(uwuContract).ownerOf(tokenId_) != address(0), "UWUGold: Token doesnt exists");
        require(IERC721(uwuContract).ownerOf(tokenId_) == _msgSender(), "UWUGold: You're not the owner");
        require(!claimed(tokenId_), "UWUGold: Already claimed");
        _mint(_msgSender(), _claimable);
        emit Claimed(_msgSender(), tokenId_, _claimable);
        return true;
    }
    
    
    function renounceOwnership() public override onlyOwner {
        _unpause();
        super.renounceOwnership();
    }
 
    function setClaimable(uint256 amount_) public onlyOwner {
        _claimable = amount_;
    }
    
    function ownerOf(uint256 tokenId_) public view returns (address){
        return IERC721(uwuContract).ownerOf(tokenId_);
    }
}