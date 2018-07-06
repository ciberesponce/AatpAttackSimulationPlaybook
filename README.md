# Introduction 
Used by Microsoft C+AI team to train and educate their customers and Partners on techniques used by red team and determined human adversaries. All too often, simply setting up a lab environment to do these attack techniques is too difficult or cumbersome so it often is skipped.  This is a mistake.

Leveraging [Azure DevTest Lab (DTL)](https://aka.ms/dtl), Microsoft C+AI Security team can provide not just an [Azure ATP SA Playbook](https://aka.ms/aatpsaplaybook) which guides you on methods and techniques, but we can leverage the DTL functionality to hydrate an environment quickly so our customers can spend more time learning and training around these techniques vs managing a lab environment.

There are limitations of what we can technically and legally provide and automate on our customers behalf.  For example, we will still require our customers to download the open-source red-team tools (i.e. [Mimikatz](https://github.com/gentilkiwi/mimikatz), [PowerShell Empire](https://github.com/EmpireProject/Empire)).  Instructions for that should appear in the product specifc suspicious activity playbooks.

![Note]
Remember, these DTL artifacts should only be used for *non-production* resources.  Microsoft has *absolutely no liability* in the use of these artifacts; the hacker and red-team tools are not from Microsoft nor do we ever recommend running VMs with antivirus turned off!

# Getting Started
Follow these high level steps to get started quickly in a lab environment 
1. Follow the Azure DevTest Lab guidance to create a new DevTest Lab within an Azure Subscription.
2. Follow [this guidance on how to re-use this repository for your own purposes](https://docs.microsoft.com/en-us/azure/lab-services/devtest-lab-add-artifact-repo)

# Questions
Have any questions? DTL specific questions should be directed to the DTL team via their [Docs site](https://docs.microsoft.com/en-us/azure/lab-services/devtest-lab-test-env).

For product specifc playbook questions (i.e. [Azure ATP Suspicious Activity Playbook](https://aka.ms/aatpsaplaybook)), those should be directed to the respective authors of those documents or on the Docs site where they are hosted.

# Want to contribute?
Want to contribute? Ideally this is community driven and we'd love your participation and contributions.  Here's how:

*TODO*:
* Join our GitHub
* Make commits!
* Email the maintainer at [aharri at microsoft.com](mailto:aharri@microsoft.com)