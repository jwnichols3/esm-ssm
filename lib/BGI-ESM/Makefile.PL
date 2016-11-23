#!/opt/OV/activeperl-5.8/bin/perl -w
#!c:/perl/bin/perl.exe -w

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'BGI::ESM::Common::INC',
    VERSION_FROM    => 'lib/BGI/ESM/Common/INC.pm'
);

WriteMakefile(
    NAME            => 'BGI::ESM::Common::Shared',
    VERSION_FROM    => 'lib/BGI/ESM/Common/Shared.pm'
);

WriteMakefile(
    NAME            => 'BGI::ESM::Common::Variables',
    VERSION_FROM    => 'lib/BGI/ESM/Common/Variables.pm'
);

WriteMakefile(
    NAME            => 'BGI::ESM::Compile::Ssm',
    VERSION_FROM    => 'lib/BGI/ESM/Compile/Ssm.pm'
);

WriteMakefile(
    NAME            => 'BGI::ESM::Compile::VpoDistribute',
    VERSION_FROM    => 'lib/BGI/ESM/Compile/VpoDistribute.pm'
);

WriteMakefile(
    NAME            => 'BGI::ESM::Compile::Ssm',
    VERSION_FROM    => 'lib/BGI/ESM/Compile/Ssm.pm'
);

#WriteMakefile(
#    NAME            => 'BGI::ESM::SelfService::ParseAlertConfig',
#    VERSION_FROM    => 'lib/BGI/ESM/SelfService/ParseAlertConfig.pm'
#);

WriteMakefile(
    NAME            => 'BGI::ESM::SelfService::SsmShared',
    VERSION_FROM    => 'lib/BGI/ESM/SelfService/SsmShared.pm'
);

#WriteMakefile(
#    NAME            => 'BGI::ESM::SelfService::SsmStatusReport',
#    VERSION_FROM    => 'lib/BGI/ESM/SelfService/SsmStatusReport.pm'
#);

WriteMakefile(
    NAME            => 'BGI::ESM::VpoServer::Alarmpoint',
    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/Alarmpoint.pm'
);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::AlternateNotification',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/AlternateNotification.pm'
#);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::DataMap',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/DataMap.pm'
#);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::LookingGlass',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/LookingGlass.pm'
#);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::Peregrine',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/Peregrine.pm'
#);

WriteMakefile(
    NAME            => 'BGI::ESM::VpoServer::ServerCommon',
    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/ServerCommon.pm'
);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::SuppressCheck',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/SuppressCheck.pm'
#);

#WriteMakefile(
#    NAME            => 'BGI::ESM::VpoServer::VPO',
#    VERSION_FROM    => 'lib/BGI/ESM/VpoServer/VPO.pm'
#);

