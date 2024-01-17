// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./WCBase.sol";
import "./TeamNFTStruct.sol";
import "./StageEnum.sol";
import "./Payable.sol";
import "./PullPayment.sol";

/**
* @dev WorldCupSweepstakeCompetition Contract implements the logic for
        1. progressing the competition tournament
        2. calculating the prize amount depending on the tournament stage (it's possible this should be split out as it gets more complicated)
        3. distribute to winning nft owners
  NOTE: 
    PullPayment - allows Winners to claim their winnings from the Escrow account (OpenZepplin)
    Payable  - allows method for checking prize pot via contract balance
               we could also fund the contract if we wanted to increase the prize pot.
**/
abstract contract WorldCupSweepstakeCompetition is
    WorldCupSweepstakeBase,
    Payable,
    PullPayment
{
    //Events
    event PrizeWin(
        address indexed _from,
        address _owner,
        string _teamId,
        TournamentStageEnum _stage,
        uint256 _prize
    );

    //Modifiers

    /**
     * @dev Modifier to test tournament progression is valid
     *      reverts if attempting to skip or duplicate stages
     **/
    modifier tournamentProgressValid(TournamentStageEnum stage){
        //Offers protection against accidently duplicating
        //tournament stage and paying out multiple times.
        require(
            stage > tournamentStage,
            "Tournament stage must progress. Either you are attempting to progress back or this is a duplicate call"
        );

        //Tournament stage should not be skipped
        require(uint(stage) == uint(tournamentStage) + 1,
            "Tournament stage must not skip a stage."
        );

        //We haven't reverted so far... so carry on...
        _;
    }

    /**
     * @dev Modifier to test tournament teams provided is valid
     *      See comment in code to see this has limited use
     **/
    modifier tournamentTeamsValid(TournamentStageEnum stage, string[] calldata teamIds){
      
      require(teamIds.length > 0, 'no teams provided');

      uint16 expectedTeams = 0;
      if(stage == TournamentStageEnum.GroupStage){
        expectedTeams = 32;
      }
      else if(stage == TournamentStageEnum.Last16){
        expectedTeams = 16;
      }
      else if(stage == TournamentStageEnum.QuaterFinal){
        expectedTeams = 8;
      }
      else if(stage == TournamentStageEnum.SemiFinal){
        expectedTeams = 4;
      }
      else if(stage == TournamentStageEnum.Final){
        expectedTeams = 2;
      }
      else if(stage == TournamentStageEnum.Champion){
        expectedTeams = 1;
      }
      else{
        revert("Unhandled stage");
      }
      
      //LIMITATION:
      //We cannot enforce exact number of teams
      //as some teams may not be minted which currently
      //will revert 'team does not exist'... (protects 
      //progressing with incorrectly entered teamid(s))
      //This is a risk as we could forget to include
      //a team... but the alternative would be to remove
      //the aforementioned revert and check if the
      //teamid is a possible team rather than minted team
      //but this requires an inefficient nested loop
      //or a restructuring to use mappings instead
      //but ain't nobody got time for that right now
      if(teamIds.length > expectedTeams){
        revert('too many teams provided');
      }
   
      //We haven't reverted so far... so carry on...
      _;
    }

    //Public Variables

    /**
     * @dev Determines the current stage that the tournament is at
     * NOTE :  Public state variables have get methods automatically generated
     **/
    TournamentStageEnum public tournamentStage = TournamentStageEnum.GroupStage;

    //Public/External Methods

    /**
     * @dev  Progresses the tournament onto the next stage
     *       progressing successful teams and allocating
     *       phased prize in a single transaction so as to
     *       simplifiy phased prize pot calculations and protect
     *       against inconsistencies where only some teams are progressed.
     * VISIBILITY: external because calldata is more efficient than memory
     *             https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices
     * WARN: Will REVERT if attempting to progress UNMINTED team via _setTeamStage...
     *       Offers some simple protection against entering unidentifiable teamIds
     *       by mistake.
     * TODO: - Does not check the number of teams are correct for each stage.
     *       - Does not stop us from skipping a tournament stage 
     * NOTE: It would be MUCH better to get this from an Oracle or other non centralised solution...
     *        e.g. Chainlink Any API to fetch from consensus driven
     *             pool of centralised data providers.
     *        however for now we'll just call it manually as each phase of the tournament ends
     *        we acknowledge this heavily centralises the project!
     *        and introduces a single point of failure!!
     **/
    function progressTournament(
        string[] calldata teamIds,
        TournamentStageEnum stage
    ) external 
    onlyOwner 
    tournamentProgressValid(stage)
    tournamentTeamsValid(stage, teamIds) {
       
        //set the current stage to the new one passed in
        //attempting to follow check-effect-interactions pattern
        tournamentStage = stage;

        //determine prize pot from current contract balance
        uint256 prizeMoney = 0;
        bool isPrizeWorthy = tournamentStageIsPrizeWorthy(stage);
        if (isPrizeWorthy) {
            //  Current Balance
            uint256 pot = getContractBalance();

            //  Calculate winnings amount per team
            prizeMoney = determinePrizeMoneyPerTeam(pot, stage);
        }

        //loop through each team and set their progression
        //and paying/attributing prize winners
        //NOTE: It can be dangerous to process too many things in a loop
        //      in case the gas block limit is reached meaning the transaction
        //      as a whole cannot be completed. 
        //      However we currently only have a maximum of 32 nft owners
        //      but if this was extended to 32 thousand nft owners we would
        //      want to consider restructuring this code:
        //      https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#gas-limit-dos-on-a-contract-via-unbounded-operations
        for (uint256 i = 0; i < teamIds.length; i++) {
            string memory teamId = teamIds[i];
            _setTeamStage(teamId, stage);

            if (isPrizeWorthy) {
                //attribute winnings
                _attributeWinnings(teamId, stage, prizeMoney);
            }
        }
    }

    /**
    * @dev Decides if the stage of the tournament is worthy of a prize or not?
    * NOTE :  Pure because this is effectively hardcoded so that it cannot be
    *         be changed. Public so anyone can see which stages of the tournament
    *         gets a prize.
    **/  
    function tournamentStageIsPrizeWorthy(TournamentStageEnum _stage)
        public
        pure
        returns (bool)
    {
        if (_stage == TournamentStageEnum.GroupStage) {
            //Tournament starts at group stage
            return false;
        } else if (
            _stage == TournamentStageEnum.Last16 ||
            _stage == TournamentStageEnum.QuaterFinal ||
            _stage == TournamentStageEnum.SemiFinal ||
            _stage == TournamentStageEnum.Final ||
            _stage == TournamentStageEnum.Champion
        ) {
            //All of these stages require a prize
            return true;
        } else {
            //Have we forgotten to write some code?
            revert("Unsupported Tournament stage");
        }
    }


    /**
    * @dev Determines the Prize per team progressing based on
    *      pot provided and stage provided.
    * NOTE :  PURE as it simply works with parameters provided
    *         PUBLIC mostly for testing but also allows users
    *         to experiment and speculate thier winnings for
    *         various stages of the tournament and for various
    *         prize pot sizes.
    **/  
    function determinePrizeMoneyPerTeam(uint256 pot, TournamentStageEnum stage)
        public
        pure
        returns (uint256)
    {
        require(pot > 0, "Prize pot must be greater than zero");

        uint256 potDivided = 0;
        uint8 prizeWorthyStagesRemaining = 5;

        // Number of teams at each stage:
        //    Last16 (16), QuaterFinal (8), SemiFinal (4), Final (2), Champion (1)
        //  Technically this code could suffer integer round downs (re link provided below)
        //  however, any small remainder balance from prize pot will be included in the next
        //  stage of the competition until the champion is declared who receives
        //  the entire remaining prize pot.
        //  Therefore have opted for code readability over fixing a problem
        //  which has negligable impact.
        //    https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/integer-division/
        if (stage == TournamentStageEnum.Last16) {
            prizeWorthyStagesRemaining = 5;
            potDivided = pot / prizeWorthyStagesRemaining / 16;
        } else if (stage == TournamentStageEnum.QuaterFinal) {
            prizeWorthyStagesRemaining = 4;
            potDivided = pot / prizeWorthyStagesRemaining / 8;
        } else if (stage == TournamentStageEnum.SemiFinal) {
            prizeWorthyStagesRemaining = 3;
            potDivided = pot / prizeWorthyStagesRemaining / 4;
        } else if (stage == TournamentStageEnum.Final) {
            prizeWorthyStagesRemaining = 2;
            potDivided = pot / prizeWorthyStagesRemaining / 2;
        } else if (stage == TournamentStageEnum.Champion) {
            //Pointless calculation because the winner takes all
            //of remaining prize pot... pattern shown to satisfy my ocd problem
            //  prizeWorthyStagesRemaining = 1;
            //  potDivided = pot / prizeWorthyStagesRemaining / 1;
            potDivided = pot;
        } else {
            if (tournamentStageIsPrizeWorthy(stage)) {
                revert(
                    "Hmmm... the developer forgot to write some code. Prize for stage is not determined."
                );
            } else {
                revert("Tournament stage does not require a prize");
            }
        }

        return potDivided;
    }

    /**
     * @dev private method to attribute winnings
     *      according to owner of nft's representing
     *      the team in quetion.    
     */
    function _attributeWinnings(
        string memory teamId,
        TournamentStageEnum stage,
        uint256 prizeMoney
    ) private {
        //  Team exists?
        require(
            teamExists(teamId),
            "Cannot attribute winnings for unminted team"
        );

        //  Determine owner
        address nftOwner = ownerOfTeam(teamId);

        //  Escrow money for winner
        _payNftOwner(nftOwner, prizeMoney);

        //  emit event for winner
        emit PrizeWin(msg.sender, nftOwner, teamId, stage, prizeMoney);
    }

    /**
     * @dev for best practice reasons and to limit
     *      reentrancy threats, winnings are moved
     *      to escrow where winners can claim/pull
     *      their unclaimed winnings via openzepplin
     *      PullPayment withdraw.
     */     
    function _payNftOwner(address nftOwner, uint256 prizeMoney)
        private
        onlyOwner
    {
        //Use OpenZepplin PullPayment from Escrow
        _asyncTransfer(nftOwner, prizeMoney);
    }
}
