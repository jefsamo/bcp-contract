// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Voting {
    struct Proposal {
        string description;
        uint voteCount;
        address creator;
        bool exists;
        uint startTime;
        uint endTime;
        string[] options;
        mapping(string => uint) optionVotes;
    }

    struct Voter {
        bool isRegistered;
        string name;
        uint age;
        mapping(uint => bool) hasVotedInProposal; // Tracks if a voter has voted in each proposal by proposal index
        mapping(uint => string) optionVotedFor; // Tracks option voted for in each proposal by proposal index
    }


    struct VoterInfo {
        address voterAddress;
        string name;
        uint age;
    }

    struct ProposalInfo {
        string description;
        uint voteCount;
        address creator;
        uint startTime;
        uint endTime;
        string[] options;
    }

    address public admin;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    address[] public registeredVoters;

    event Vote(address indexed voter);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "Only registered voters can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

   // Register a voter with name and age (only admin can call this function)
    function registerVoter(address _voter, string memory _name, uint _age) external onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        require(_age >= 18, "Voter must be at least 18 years old");

        voters[_voter].isRegistered = true;
        voters[_voter].name = _name;
        voters[_voter].age = _age;
        registeredVoters.push(_voter);
    }

    // Function to list all registered voters ["Yes", "No", "Indifferent"] 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    // 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
    // 0x17F6AD8Ef982297579C203069C1DbfFE4348c372
    function listRegisteredVoters() external view returns (address[] memory) {
        return registeredVoters;
    }

    // Create a new proposal with a start time, end time, and options (only registered voters can create proposals)
    function createProposal(
        string memory _description,
        uint _startTime,
        uint _endTime,
        string[] memory _options
    ) external onlyAdmin {
        require(_startTime < _endTime, "Start time must be before end time");

        Proposal storage newProposal = proposals.push();
        newProposal.description = _description;
        newProposal.voteCount = 0;
        newProposal.creator = msg.sender;
        newProposal.exists = true;
        newProposal.startTime = _startTime;
        newProposal.endTime = _endTime;
        newProposal.options = _options;

        for (uint i = 0; i < _options.length; i++) {
            newProposal.optionVotes[_options[i]] = 0;
        }
    }
    function updateProposal(
        uint _proposalIndex,
        string memory _newDescription,
        uint _newStartTime,
        uint _newEndTime,
        string[] memory _newOptions
    ) external onlyAdmin {
        require(proposals[_proposalIndex].exists, "Proposal does not exist");
        require(_newStartTime < _newEndTime, "Start time must be before end time");

        Proposal storage proposal = proposals[_proposalIndex];
        proposal.description = _newDescription;
        proposal.startTime = _newStartTime;
        proposal.endTime = _newEndTime;
        proposal.options = _newOptions;

        // Reset vote counts for new options
        for (uint i = 0; i < _newOptions.length; i++) {
            proposal.optionVotes[_newOptions[i]] = 0;
        }

        // Reset total vote count
        proposal.voteCount = 0;
    }


 // Cast a vote for a specific option in a proposal (one vote per voter per proposal)
    function vote(uint _proposalIndex, string memory _option) external onlyRegisteredVoter {
        require(proposals[_proposalIndex].exists, "Proposal does not exist");
        require(block.timestamp >= proposals[_proposalIndex].startTime, "Voting has not started yet");
        require(block.timestamp < proposals[_proposalIndex].endTime, "Voting has ended");

        Voter storage voter = voters[msg.sender];
        require(!voter.hasVotedInProposal[_proposalIndex], "Voter has already voted in this proposal");

        Proposal storage proposal = proposals[_proposalIndex];
        bool optionExists = false;

        for (uint i = 0; i < proposal.options.length; i++) {
            if (keccak256(abi.encodePacked(proposal.options[i])) == keccak256(abi.encodePacked(_option))) {
                optionExists = true;
                break;
            }
        }

        require(optionExists, "Invalid option");

        voter.hasVotedInProposal[_proposalIndex] = true;
        voter.optionVotedFor[_proposalIndex] = _option;

        proposal.optionVotes[_option]++;
        proposal.voteCount++;

        emit Vote(msg.sender);
    }

    // Get the total number of proposals
    function getTotalVoters() external view returns (uint) {
        return registeredVoters.length;
    }

     // Get the total number of proposals
    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }

    // View proposal details
    function viewProposal(uint _proposalIndex) external view returns (
        string memory description,
        uint voteCount,
        address creator,
        uint startTime,
        uint endTime,
        string[] memory options
    ) {
        require(proposals[_proposalIndex].exists, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalIndex];
        return (
            proposal.description,
            proposal.voteCount,
            proposal.creator,
            proposal.startTime,
            proposal.endTime,
            proposal.options
        );
    }

    // Get votes for each option of a proposal
    function getOptionVotes(uint _proposalIndex) external view returns (string[] memory options, uint[] memory votes) {
        require(proposals[_proposalIndex].exists, "Proposal does not exist");

        Proposal storage proposal = proposals[_proposalIndex];
        uint optionCount = proposal.options.length;
        options = new string[](optionCount);
        votes = new uint[](optionCount);

        for (uint i = 0; i < optionCount; i++) {
            options[i] = proposal.options[i];
            votes[i] = proposal.optionVotes[options[i]];
        }
    }

    // Function to list all proposals
    // function listProposals() external view returns (string[] memory, uint[] memory, address[] memory) {
        function listProposals() external view returns (string[] memory, uint[] memory) {
        uint proposalCount = proposals.length;
        string[] memory descriptions = new string[](proposalCount);
        uint[] memory voteCounts = new uint[](proposalCount);
        // address[] memory creators = new address[](proposalCount);

        for (uint i = 0; i < proposalCount; i++) {
            descriptions[i] = proposals[i].description;
            voteCounts[i] = proposals[i].voteCount;
            // creators[i] = proposals[i].creator;
        }

        // return (descriptions, voteCounts, creators);
        return (descriptions, voteCounts);
    }

    // Get the winning option in a proposal
    function getWinningOption(uint _proposalIndex) external view returns (string memory winningOption, uint winningVotes) {
        require(proposals[_proposalIndex].exists, "Proposal does not exist");
        require(block.timestamp >= proposals[_proposalIndex].endTime, "Voting period has not ended");

        Proposal storage proposal = proposals[_proposalIndex];
        uint highestVoteCount = 0;

        for (uint i = 0; i < proposal.options.length; i++) {
            string memory option = proposal.options[i];
            uint optionVoteCount = proposal.optionVotes[option];
            if (optionVoteCount > highestVoteCount) {
                highestVoteCount = optionVoteCount;
                winningOption = option;
            }
        }
        winningVotes = highestVoteCount;
    }

    function getTotalVotesForProposal(uint _proposalIndex) external view returns(uint){
        require(proposals[_proposalIndex].exists, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalIndex];

        uint count = 0;

        for(uint i = 0; i < proposal.options.length; i++){
           count += proposal.optionVotes[proposal.options[i]];
        }

        return count;
    }

    function getAllVoters() external view returns (VoterInfo[] memory) {
        uint totalVoters = registeredVoters.length;
        VoterInfo[] memory votersList = new VoterInfo[](totalVoters);

        for (uint i = 0; i < totalVoters; i++) {
            address voterAddress = registeredVoters[i];
            votersList[i] = VoterInfo({
                voterAddress: voterAddress,
                name: voters[voterAddress].name,
                age: voters[voterAddress].age
            });
        }

        return votersList;
    }


     function getAllProposals() external view returns (ProposalInfo[] memory) {
        uint totalProposals = proposals.length;
        ProposalInfo[] memory proposalsList = new ProposalInfo[](totalProposals);

        for (uint i = 0; i < totalProposals; i++) {
            proposalsList[i] = ProposalInfo({
               creator: proposals[i].creator,
                voteCount:proposals[i].voteCount,
                startTime: proposals[i].startTime,
                endTime: proposals[i].endTime,
                options:proposals[i].options,
                description: proposals[i].description
            });
        }

        return proposalsList;
    }

    function voterExist(address _address) public view returns (bool) {
        for (uint i = 0; i < registeredVoters.length; i++) {
            if (registeredVoters[i] == _address) {
                return true; 
            }
        }
        return false; 
    }
}