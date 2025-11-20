Perl Development Environment
============================

The Perl development enviornment uses [Dist::Zilla](https://dzil.org/), accessible from the command-line as "dzil". You can install Dist::Zilla by various methods.

* [installing from source](https://www.cpan.org/modules/INSTALL.html):

    cpan Dist::Zilla Dist::Zilla::Plugin::Config::Git Dist::Zilla::Plugin::Git Dist::Zilla::Plugin::PodWeaver Dist::Zilla::Plugin::ReadmeFromPod Dist::Zilla::Plugin::GithubMeta Dist::Zilla::Role::ModuleMetadata
  
* RPM-based Linux distributions (Fedora, Red Hat, Rocky, Alma):

    dnf install perl-Dist-Zilla perl-Dist-Zilla-Plugin-Config-Git perl-Dist-Zilla-Plugin-Git perl-Dist-Zilla-Plugin-PodWeaver perl-Dist-Zilla-Plugin-ReadmeFromPod perl-Dist-Zilla-Plugin-GithubMeta perl-Dist-Zilla-Role-ModuleMetadata

* DEB-based Linux distributions (Debian, Ubuntu, RasPiOS):

    apt install libdist-zilla-perl libdist-zilla-plugin-config-git-perl libdist-zilla-plugin-git-perl libdist-zilla-plugin-podweaver-perl libdist-zilla-plugin-readmefrompod-perl libdist-zilla-plugin-githubmeta-perl libdist-zilla-role-modulemetadata-perl

Use Dist::Zilla's dzil command to set up, build and install. Change into the development directory src/perl/prefvote or src/perl/kr2 first.

    dzil authordeps --missing | cpanm --notest
    dzil listdeps --missing | cpanm --notest
    dzil build
    dzil test
    dzil install
