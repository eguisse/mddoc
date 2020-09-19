#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
  Makefile to generate the html and pdf file.
  It combines multiple md files into 1 combined md file.

  Copyright (c) 2018 - 2020, Emmanuel GUISSE

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
"""

import os
from pathlib import Path
import shutil
import sys
import codecs
import yaml
import time
import logging.config
from collections import UserDict
import re
import argparse
import git
import subprocess
from subprocess import Popen, PIPE

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
logger = logging.getLogger(__name__)


def delfile(filename: str):
    """
    Delete file if exists
    :param filename: filename to delete
    :return:
    """
    logger.debug("start delfile " + filename)
    if os.path.exists(filename):
        os.remove(filename)


def makedirs(dirname: str):
    """
    Create a directory on filesystem
    :param dirname:
    :return:
    """
    logger.debug("start makedirs " + dirname)
    try:
        os.makedirs(dirname)
    except FileExistsError:
        logger.error("ERROR cannot create directory: " + dirname)
        pass


class Transform:
    """
    Generate the report in markdown format
    """

    def __init__(self, config_filename: str = None, docs_path: str = None, build_path: str = None, project_path: str = None,
                 encoding: str = "utf-8", resource_path: str = None, output_filename: str = None, site_path: str = None):
        """
        Object builder
        :param config_filename:
        :param docs_path:
        :param build_path:
        :param encoding:
        """
        logger.debug("param config_filename = [%s]" % config_filename)
        logger.debug("param docs_path = [%s]" % docs_path)
        logger.debug("param build_path = [%s]" % build_path)
        logger.debug("param project_path = [%s]" % project_path)
        logger.debug("param encoding = [%s]" % encoding)
        logger.debug("param resource_path = [%s]" % resource_path)
        logger.debug("param output_filename = [%s]" % output_filename)

        self.page = None
        self.pages = []
        self.current_path = os.getcwd()

        self.config_data: UserDict = None

        self.project_path: str = None
        if project_path is None:
            # default mount point for Docker container
            self.project_path = "/mnt"
        else:
            self.project_path = project_path

        self.docs_path: str = None
        if docs_path is None:
            self.docs_path =  os.path.join(self.project_path, "doc")
        else:
            self.docs_path = os.path.join(self.project_path, docs_path)

        self.config_filename: str = None
        if config_filename is None:
            self.config_filename = os.path.join(self.docs_path, "mddoc.yml")
        else:
            self.config_filename = os.path.join(self.project_path, config_filename)

        self.config_file = None

        self.build_path: str = None
        if build_path is None:
            self.build_path = os.path.join(self.current_path, "build")
        else:
            self.build_path = os.path.join(self.project_path, build_path)

        self.site_path: str = None
        if site_path is None:
            self.site_path = os.path.join(self.current_path, "site")
        else:
            self.site_path = os.path.join(self.project_path, site_path)

        self.outfile: str = None
        self.resource_path: str = None
        self.mddoc_runtime_path: str = os.environ.get('MDDOC_RUNTIME_PATH', self.current_path)
        logger.debug("mddoc_runtime_path = " + self.mddoc_runtime_path)
        self.local_resource_path = os.path.join(self.mddoc_runtime_path, "resources")
        if resource_path is None:
            self.resource_path = self.local_resource_path
        else:
            self.resource_path = os.path.join(self.project_path, resource_path)
        logger.debug("resource_path = " + self.resource_path)

        self.pdf_out_filename: str = None
        self.filename: str = None
        if output_filename is None:
            self.pdf_out_filename = None
        else:
            self.pdf_out_filename = os.path.join(self.project_path, output_filename)

        self.combined_md_file = None
        self.encoding = encoding
        self.git_version = ""
        self.git_date = ""
        self.git_remote_url = ""
        self.pdf_page1_html: str = ""
        if resource_path is not None and os.path.exists(os.path.join(self.resource_path, "pdf-page1.html")):
            self.pdf_page1_html = os.path.join(self.resource_path, "pdf-page1.html")
        else:
            self.pdf_page1_html = os.path.join(self.local_resource_path, "pdf-page1.html")
        self.pdf_header_html: str = ""
        if resource_path is not None and os.path.exists(os.path.join(self.resource_path, "pdf-header.html")):
            self.pdf_header_html = os.path.join(self.resource_path, "pdf-header.html")
        else:
            self.pdf_header_html = os.path.join(self.local_resource_path, "pdf-header.html")
        self.pdf_footer_html: str = ""
        if resource_path is not None and os.path.exists(os.path.join(self.resource_path, "pdf-footer.html")):
            self.pdf_footer_html = os.path.join(self.resource_path, "pdf-footer.html")
        else:
            self.pdf_footer_html = os.path.join(self.local_resource_path, "pdf-footer.html")
        self.template_html: str = ""
        if resource_path is not None and os.path.exists(os.path.join(self.resource_path, "GitHub.html5")):
            self.template_html = os.path.join(self.resource_path, "GitHub.html5")
        else:
            self.template_html = os.path.join(self.local_resource_path, "GitHub.html5")
        self.css_file: str = ""
        if resource_path is not None and os.path.exists(os.path.join(self.resource_path, "pandoc.css")):
            self.css_file = os.path.join(self.resource_path, "pandoc.css")
        else:
            self.css_file = os.path.join(self.local_resource_path, "pandoc.css")
        self.site_build_path = os.path.join(self.build_path, "site")
        self.site_img_path = os.path.join(self.site_build_path, 'images')
        self.site_diagram_dir = os.path.join(self.site_build_path, 'diagrams')
        self.mkdocs_config_filename = os.path.join(self.build_path, "mkdocs.yaml")
        self.do_get_git_history = True
        self.include_index_page = False
        self.doc_toc = []
        self.chapter_autonumbering = True
        self.include_table_of_contents = True
        self.git_history = []

    def parsefile(filename):
        logger.debug("start parsefile")

    def flatten_pages(self, pages, level=1):
        """Recursively flattens pages data structure into a one-dimensional data structure
        extract from https://github.com/twardoch/mkdocs-combine/blob/master/mkdocs_combine/mkdocs_combiner.py
        """
        logger.debug("start flatten_pages")
        flattened = []

        str_type = (str, self.encoding)

        for page in pages:
            if type(page) in str_type:
                flattened.append(
                    {
                        u'file': page,
                        u'title': u'%s {: .page-title}' % page[0:40],  # bug here
                        u'level': level,
                    })
            if type(page) is list:
                flattened.append(
                    {
                        u'file': page[0],
                        u'title': u'%s {: .page-title}' % page[1],
                        u'level': level,
                    })
            if type(page) is dict:
                if type(list(page.values())[0]) in (str, self.encoding):
                    flattened.append(
                        {
                            u'file': list(page.values())[0],
                            u'title': u'%s {: .page-title}' % list(page.keys())[0],
                            u'level': level,
                        })
                if type(list(page.values())[0]) is list:
                    # Add the parent section
                    flattened.append(
                        {
                            u'file': None,
                            u'title': u'%s {: .page-title}' % list(page.keys())[0],
                            u'level': level,
                        })
                    # Add children sections
                    flattened.extend(
                        self.flatten_pages(
                            list(page.values())[0],
                            level + 1)
                    )
        return flattened

    def open_file_combined(self):
        """
        Create markdown file combined.md
        """
        logger.debug("start open_file_combined")
        self.outfile = os.path.join(self.build_path, 'combined.md')
        self.combined_md_file = codecs.open(self.outfile, 'w', encoding=self.encoding)
        self.combined_md_file.write('\n\n<div class=\"new-page\"></div>\n\n')

    def close_file_combined(self):
        """
        Close the markdown file combined.md
        """
        logger.debug("start close_file_combined(")
        self.combined_md_file.write('\n\n')
        self.combined_md_file.close()

    def get_git_history(self):
        """
        Create the change history page.
        Only commit with tag are listed.
        :return:
        """
        logger.debug("start get_git_history")
        # Log git history
        self.git_history.append("| Name           | Date | Version | Change Reference |")
        self.git_history.append("|----------------|------|---------|------------------|")

        # repo_path = os.getenv('GIT_REPO_PATH')
        repo_path = self.project_path
        logger.debug("GIT_REPO_PATH=" + repo_path)
        # check if .git is a repository, not a submodule
        # because when running in docker container, mount point is the repo. Cannot go to the parent directory.
        if os.path.isfile(os.path.join(repo_path,".git")):
            logger.error("mddoc does not support submodule")
            raise NameError("mddoc does not support submodule")

        g = git.Git(repo_path)
        try:
            self.git_history.append(re.sub('"', '', str(
                g.log('--no-walk', '--reverse', '--tags', '--pretty="| %an | %cD | %d | %s |"', '--abbrev-commit'))))
        except IndexError:
            logger.error("WARNING: git repository has no tag in history. Cannot build change record")

        # Get the last commit
        repo = git.Repo(repo_path)
        self.git_date = str(repo.active_branch.commit.committed_datetime)
        self.git_remote_url = next(repo.remote().urls)
        self.git_version = None
        try:
            #self.git_version = str(repo.tags[-1]) + "_" + str(g.log('--pretty=%h', '-n 1'))
            self.git_version = re.sub('"', '', str(g.log('-n', '1', '--no-walk', '--pretty="commit %h %d"', '--abbrev-commit')))
        except (AttributeError,IndexError):
            logger.error("WARNING: cannot get current version from git")
            pass
        logger.debug("self.git_version=" + self.git_version)

        if self.git_version is not None:
            # insert into combined.md for pdf file
            self.combined_md_file.write("## Change Record\n")
            self.combined_md_file.write("\n")
            for lline in self.git_history:
                self.combined_md_file.write(lline + '\n')
            self.combined_md_file.write('\n\n<div class=\"new-page\"></div>\n\n')

            # Now create a file for the web site
            makedirs(self.site_build_path)
            cr_filename = os.path.join(self.site_build_path, 'change_record.md')
            cr = codecs.open(cr_filename, 'w', encoding=self.encoding)
            cr.write('# Change record\n\n')
            for lline in self.git_history:
                cr.write(lline + '\n')
            cr.write('\n')
            cr.close()

    def convert_puml_2_png(self, in_file_name):
        """
        convert a puml file to png file
        :return:
        """
        logger.debug("start convert_puml_2_png, file_name=" + in_file_name)
        cmdline = ['/usr/local/bin/plantuml', "-tpng", '-o', self.site_img_path, in_file_name]
        try:
            p = subprocess.run(cmdline, check=True, text=True)
            print(p.stdout)
        except Exception as exc:
            raise Exception('Failed to run plantuml: %s' % exc)
        else:
            if p.returncode != 0:
                # plantuml returns a nice image in case of syntax error so log but still return out
                print('Error in "uml" directive: %s' % p.stderr)

    def create_menu(self):
        """ Parse all md pages listed in mkdocs config file
        and create pages for readthedoc web site
        :return:
        """
        logger.debug("start create_menu")
        mergedlines = []
        self.doc_toc = []
        menu_level_1 = 1
        puml_files_list = []
        index_page_toc = []
        index_page_exists = False
        #self.combined_md_file.write('# ' + self.config_data[u'site_name'] + "\n\n")

        makedirs(self.site_build_path)
        makedirs(os.path.join(self.site_build_path, 'diagrams'))

        for page in self.pages:
            logger.debug("open file=" + page[u'file'])
            lines_tmp = []

            # ignore if index.md file
            if (page[u'file'] and not page[u'file'] == 'index.md') or (page[u'file'] and page[u'file'] == 'index.md' and self.include_index_page is True):
                fname = os.path.join(self.docs_path, page[u'file'])
                try:
                    # open the md document
                    with codecs.open(fname, 'r', self.encoding) as p:
                        # start to build the chapter with number
                        # we increase the level of the chapter for the global doc.
                        # chapter in code are ignored, printed asis
                        # yaml metadata are not printed

                        not_in_code_block = True
                        in_meta = False
                        in_plantuml = False
                        in_chapter_line = False
                        menu_level_2 = 0
                        menu_level_3 = 0
                        menu_level_4 = 0
                        menu_level_5 = 0
                        line_number = 0
                        site_line = ""
                        meta_line_number = 0
                        # mergedlines.append("<span id=page_" + page[u'file'] + "></span>")

                        site_build_filename = os.path.join(self.site_build_path, page[u'file'])
                        site_page = codecs.open(site_build_filename, 'w', encoding=self.encoding)
                        puml_file = None
                        puml_file_id = 1

                        for line in p.readlines():
                            line_number += 1
                            site_line = line

                            # Manage code block
                            if line.startswith("```"):
                                not_in_code_block = not not_in_code_block
                                if in_plantuml:
                                    in_plantuml = False
                                    site_line = '\n'
                                    if puml_file is not None:
                                        puml_file.write("@enduml\n")
                                        puml_file.close()
                                        puml_file = None
                                        puml_filename = None

                            if not_in_code_block is True:
                                # replace link to other markdown page
                                # from: See doc [page2](page2.md)
                                # by  : See doc [page2](#page_page2.md)
                                m = re.search('\[(.*?)]\(#(.*?)\)', line)
                                if m:
                                    logger.debug("line match1 " + m.group(1) + " " + m.group(2) + ' for line=' + line)
                                    line = re.sub('\[(.*?)]\(#', '[<a href="#menu_' + re.sub(' ', '-', m.group(2)) + '">' + m.group(1) + '</a>](#', line)
                                    line = re.sub(']\(#(.*?)\)', '](#menu_' + re.sub(' ', '-',  m.group(2)) + ')', line)
                                    #line = re.sub(']\(#(.*?)\)', '](#menu_\\1)', line)
                                else:
                                    m = re.search('\[(.*?)]\((.*?).md\)', line)
                                    if m:
                                        logger.debug("line match2 " + m.group(1) + " " + m.group(2) + ' for line=' + line)
                                        line = re.sub('\[(.*?)]\(', '[<a href="#page_' + re.sub(' ', '-', m.group(2)) + '.md">' + m.group(1) + '</a>](', line)
                                        line = re.sub(']\((.*?)\)', '](#page_' + re.sub(' ', '-',  m.group(2)) + ')', line)
                                    #line = re.sub(']\((.*?).md\)', '](#page_\\1.md)', line)

                                # copy images
                                # search for image
                                m = re.search('!\[(.*?)]\((.*?)\)', site_line)
                                if m:
                                    img_filename = m.group(2)
                                    logger.debug("copy image file: " + img_filename)
                                    img_filepath = Path(os.path.join(self.docs_path, img_filename))
                                    if img_filepath.exists() and img_filepath.is_file():
                                        dest_img_filename = os.path.join(self.site_build_path,  img_filename)
                                        dest_img_filepath = Path(dest_img_filename)
                                        logger.debug("dest_img_filepath: " + str(dest_img_filepath.parent))
                                        if not dest_img_filepath.parent.exists():
                                            makedirs(str(dest_img_filepath.parent))
                                        dest_img_filename = os.path.join(self.site_build_path,  img_filename)
                                        shutil.copy(os.path.join(self.docs_path, img_filename), dest_img_filename)

                                in_chapter_line = False
                                if re.match(r'^#######+', line):
                                    line = re.sub(r'^#######+', '######', line)

                                elif re.match(r'^#####', line):
                                    menu_level = 5
                                    menu_level_5 = menu_level_5 + 1
                                    chapter_number = str(menu_level_1) + '.' + str(menu_level_2) + '.' + str(menu_level_3) + '.' + str(menu_level_4) + '.' + str(menu_level_5)
                                    in_chapter_line = True
                                    chapter_line_title = (re.sub(r'^#####', '', line)).rstrip('\r\n')

                                elif re.match(r'^####', line):
                                    menu_level = 4
                                    menu_level_4 = menu_level_4 + 1
                                    menu_level_5 = 1
                                    chapter_number = str(menu_level_1) + '.' + str(menu_level_2) + '.' + str(menu_level_3) + '.' + str(menu_level_4)
                                    in_chapter_line = True
                                    chapter_line_title = (re.sub(r'^####', '', line)).rstrip('\r\n')

                                elif re.match(r'^###', line):
                                    menu_level = 3
                                    menu_level_3 = menu_level_3 + 1
                                    menu_level_4 = 1
                                    menu_level_5 = 1
                                    chapter_number = str(menu_level_1) + '.' + str(menu_level_2) + '.' + str(menu_level_3)
                                    in_chapter_line = True
                                    chapter_line_title = (re.sub(r'^###', '', line)).rstrip('\r\n')

                                elif re.match(r'^##', line):
                                    menu_level = 2
                                    menu_level_2 = menu_level_2 + 1
                                    menu_level_3 = 1
                                    menu_level_4 = 1
                                    menu_level_5 = 1
                                    chapter_number = str(menu_level_1) + '.' + str(menu_level_2)
                                    in_chapter_line = True
                                    chapter_line_title = (re.sub(r'^##', '', line)).rstrip('\r\n')

                                elif re.match(r'^#', line):
                                    menu_level = 1
                                    menu_level_1 = menu_level_1 + 1
                                    menu_level_2 = 1
                                    menu_level_3 = 1
                                    menu_level_4 = 1
                                    menu_level_4 = 1
                                    chapter_number = str(menu_level_1)
                                    in_chapter_line = True
                                    chapter_line_title = (re.sub(r'^#', '', line)).rstrip('\r\n')

                                if in_chapter_line is True:
                                    # We modify the line with chapter
                                    menuid = 'menuid_' + chapter_number
                                    # Add chapter number if required
                                    if self.chapter_autonumbering is True:
                                        new_chapter_line_title = chapter_number + ' ' + chapter_line_title
                                        # For the index page of the pdf document
                                        self.doc_toc.append('- [<a href="#' + menuid + '">' + '&nbsp;' * (menu_level - 1) * 2 + new_chapter_line_title + '</a>](#' + menuid + ')')
                                    else:
                                        new_chapter_line_title = '&nbsp;' * (menu_level - 1) * 2 + chapter_line_title
                                        # For the index page of the pdf document
                                        self.doc_toc.append('- [<a href="#' + menuid + '">' + new_chapter_line_title + '</a>](#' + menuid + ')')
                                    # For web site, just rename the title
                                    site_line = "#" * menu_level + ' ' + new_chapter_line_title + '\n'
                                    # For pdf doc, need to increment by 1 the Menu level, + add span id to create the link to the page
                                    if menu_level == 1:
                                        line = "#" * (menu_level + 1 ) + ' <span id="' + menuid + '">' + new_chapter_line_title \
                                        + '</span><span id="page_' + page[u'file'] + '">&nbsp;</span>\n'
                                        # Create index page for the web site
                                        index_page_toc.append('- [' + new_chapter_line_title + '](' + page[u'file'] + ')')
                                    else:
                                        line = "#" * (menu_level + 1 ) + ' <span id="' + menuid + '">' + new_chapter_line_title \
                                        + '</span><span id="menu_' + re.sub(' ', '-', chapter_line_title) + '">&nbsp;</span>\n'

                                if line.startswith("---") and meta_line_number == 0:
                                    in_meta = True

                                if line.startswith("---") and meta_line_number > 1:
                                    in_meta = False

                                if in_meta is True:
                                    # remove meta data in the beginning of the page
                                    line = '\n'
                                    site_line = '\n'
                                    meta_line_number += 1

                                if line.startswith("[TOC]"):
                                    line = '\n'
                                    site_line = '\n'

                            else:  # i am in codeblock
                                if line.startswith("```plantuml"):
                                    # If plantuml code block, then create a dedicated puml file file for the diagram.
                                    # mkdocs does not support puml code in markdown doc.
                                    in_plantuml = True
                                    puml_file_id = puml_file_id + 1
                                    base_puml_filename = page[u'file'] + "_puml_" + str(puml_file_id)
                                    l_buf = os.path.join("diagrams", base_puml_filename)
                                    puml_filename = os.path.join(self.site_build_path, l_buf + ".puml")
                                    puml_files_list.append(puml_filename)
                                    logger.debug("generate puml file: " + puml_filename )
                                    site_page.write("![Diagram " + str(puml_file_id) + "](images/" + base_puml_filename + ".png" + ")\n")
                                    puml_file = codecs.open(puml_filename, 'w', encoding=self.encoding)
                                    puml_file.write("@startuml\n")
                                    site_line = ''

                                elif in_plantuml:
                                    site_line = ''
                                    if puml_file is not None:
                                        puml_file.write(line)

                            mergedlines.append(line)
                            site_page.write(site_line)
                        site_page.close()

                except IOError as e:
                    raise Exception("Couldn't open %s for reading: %s" % (fname, e.strerror), 1)

                mergedlines.append('\n\n<div class=\"new-page\"></div>\n\n')
            else:
                # we are in page index.md and self.include_index_page is False
                index_page_exists = True

        if self.include_table_of_contents is True:
            # For the web site:
            # Create table_of_contents.md page for site
            site_build_filename = os.path.join(self.site_build_path, 'table_of_contents.md')
            site_page = codecs.open(site_build_filename, 'w', encoding=self.encoding)
            site_page.write('# Table of Contents\n\n')
            for lline in index_page_toc:
                site_page.write(lline + '\n')
            site_page.write('\n')
            site_page.close()

            # For pdf doc:
            # write TOC
            self.combined_md_file.write('\n## Table of Contents\n\n')
            for lline in self.doc_toc:
                self.combined_md_file.write(lline + '\n')
            self.combined_md_file.write('\n\n<div class=\"new-page\"></div>\n\n')

        for lline in mergedlines:
            self.combined_md_file.write(lline)

        for puml_file in puml_files_list:
            self.convert_puml_2_png(puml_file)

    def load_config(self):
        """
        Read the mddoc.yml configuration file
        :param config_filename:
        :return:
        """
        logger.debug("start load_config, configuration file: {}".format(self.config_filename))

        with open(self.config_filename) as file:
            # The FullLoader parameter handles the conversion from YAML
            # scalar values to Python the dictionary format
            self.config_data = yaml.load(file, Loader=yaml.FullLoader)

        """ @TODO @BUG TypeError: self.config_data[u'docs_dir'] = 'docs' list indices must be integers or slices, not str
        """
#        if not "docs_dir" in self.config_data:
#            self.config_data[u'docs_dir'] = 'docs'
        if "site_dir" not in self.config_data:
            self.config_data[u'site_dir'] = 'site'

        if self.pdf_out_filename is None:
            if 'pdf_out_filename' in self.config_data[u'extra']:
                self.pdf_out_filename = os.path.join(self.build_path, self.config_data[u'extra'][u'pdf_out_filename'])
            else:
                self.pdf_out_filename = os.path.join(self.build_path,'report.pdf')

        if 'filename' in self.config_data[u'extra']:
            self.filename = self.config_data[u'extra'][u'filename']
        else:
            self.filename = 'report.pdf'

        if self.docs_path is None:
            if 'docs_dir' in self.config_data:
                self.docs_path = os.path.join(self.project_path, self.config_data[u'docs_dir'])
            else:
                self.docs_path = os.path.join(self.project_path, "doc")

        if 'git_history' in self.config_data[u'extra']:
            logger.debug("got extra.git_history = " + str(self.config_data[u'extra'][u'git_history']))
            self.do_get_git_history = self.config_data[u'extra'][u'git_history']

        if 'include_index_page' in self.config_data[u'extra']:
            self.include_index_page =  self.config_data[u'extra'][u'include_index_page']

        if 'chapter_autonumbering' in self.config_data[u'extra']:
            self.chapter_autonumbering = self.config_data[u'extra'][u'chapter_autonumbering']

        if 'include_table_of_contents' in self.config_data[u'extra']:
            self.include_table_of_contents = self.config_data[u'extra'][u'include_table_of_contents']

        logger.debug("docs_path=" + self.docs_path)
        logger.debug("site_dir=" + self.config_data[u'site_dir'])
        logger.debug("pdf_outfilename=" + self.pdf_out_filename)

        self.pages = self.flatten_pages(self.config_data["nav"])

    def debug_info_config(self):
        logger.debug("debug info")

    def export_env(self):
        """
        Export environment variables will be used by the parent shell script
        :return:
        """
        logger.debug("start export_env")
        outfile = os.path.join(self.build_path, 'combined.env')
        logger.debug("start building file: " + outfile)
        f = codecs.open(outfile, 'w', encoding=self.encoding)

        if self.pdf_out_filename is None:
            self.pdf_out_filename = os.path.join(self.build_path, "report.pdf")

        def setenv(name: str, value: str):
            os.environ[name] = value
            logger.debug("set value " + name + "=" + value)
            f.write(name + "=\"" + value + "\"\n")

        setenv("_TITLE", self.config_data[u'site_name'])
        setenv("_AUTHOR", self.config_data[u'site_author'])
        setenv("_STATUS", self.config_data[u'extra'][u'status'])
        setenv("_DATE", self.config_data[u'extra'][u'published_date'])
        setenv("_SUBJECT", self.config_data[u'site_description'])
        setenv("_VERSION", self.config_data[u'extra'][u'version'])
        setenv("_RIGHTS", self.config_data[u'copyright'])
        setenv("_SOURCE_URL", self.config_data[u'repo_url'])
        setenv("_FILENAME", self.filename)
        setenv("_PROJECTNAME", self.config_data[u'extra'][u'project_name'])
        setenv("_CONFIDENTIALITY", self.config_data[u'extra'][u'confidentiality'])
        setenv("_COMPANY_NAME", self.config_data[u'extra'][u'company_name'])
        setenv("_COMPANY_URL", self.config_data[u'extra'][u'company_url'])
        setenv("_OWNER", self.config_data[u'extra'][u'document_owner'])
        setenv("_GIT_VERSION", self.git_version)
        setenv("_GIT_DATE", self.git_date)
        setenv("_GIT_REPONAME", self.git_remote_url)
        setenv("_DOC_PATH", self.docs_path)
        setenv("_BUILD_PATH", self.build_path)
        setenv("_RUNTIME_PATH", self.mddoc_runtime_path)
        setenv("_RESOURCE_PATH", self.resource_path)
        setenv("_PDFOUTFILE", self.pdf_out_filename)
        setenv("_PDF_PAGE1_HTML", self.pdf_page1_html)
        setenv("_PDF_HEADER_HTML", self.pdf_header_html)
        setenv("_PDF_FOOTER_HTML", self.pdf_footer_html)
        setenv("_TEMPLATE_HTML", self.template_html)
        setenv("_CSS_FILE", self.css_file)
        setenv("_SITE_BUILD_PATH", self.site_build_path)
        setenv("_SITE_PATH", self.site_path)
        setenv("_CONFIG_FILENAME", self.config_filename)
        setenv("_MKDOCS_CONFIG_FILENAME", self.mkdocs_config_filename)

        if 'wkhtmltopdf_opts' in self.config_data[u'extra']:
            setenv("_WKHTMLTOPDF_OPTS", self.config_data[u'extra'][u'wkhtmltopdf_opts'])
        if 'pandoc_opts' in self.config_data[u'extra']:
            setenv("_PANDOC_OPTS", self.config_data[u'extra'][u'pandoc_opts'])
        if 'pdf_meta_keywords' in self.config_data[u'extra']:
            setenv("_PDF_META_KEYWORDS", self.config_data[u'extra'][u'pdf_meta_keywords'])
        f.close()

    def clean(self):
        """
        Clean temporary files in build directory
        :return:
        """
        logger.debug("start clean")
        makedirs(self.build_path)
        delfile(os.path.join(self.build_path, 'combined.md'))
        delfile(os.path.join(self.build_path, 'combined.env'))
        delfile(os.path.join(self.build_path, 'combined.html'))
        delfile(os.path.join(self.build_path, 'pdf-page1.html'))
        delfile(os.path.join(self.build_path, 'pdf-header.html'))
        delfile(os.path.join(self.build_path, 'pdf-footer.html'))
        delfile(os.path.join(self.build_path, 'combined.pdf'))

    def create_mkdoc_conf_file(self):
        """
        Create the mkdoc configuration file
        :return:
        """
        logger.debug("start create_mkdoc_conf_file")
        if self.config_data is None:
            raise Exception('ERROR: configuration file is not loaded')

        mkdocs_config_data = self.config_data
        mkdocs_config_data[u'docs_dir'] = self.site_build_path
        mkdocs_config_data[u'site_dir'] = self.site_path
        if self.include_table_of_contents is True:
            mkdocs_config_data[u'nav'].insert(0,{'Table of Contents': 'table_of_contents.md'})

        if self.do_get_git_history is True and self.git_version is not None:
            mkdocs_config_data[u'nav'].append({'Change record': 'change_record.md'})

        logger.debug("create file: " + self.mkdocs_config_filename)
        with open(os.path.join(self.build_path, self.mkdocs_config_filename), 'w') as mkdocs_config_file:
            documents = yaml.dump(mkdocs_config_data, mkdocs_config_file)


#
# Main procedure
#
# logging.basicConfig(stream=sys.stdout, level=logging.INFO)


"""
    ==========================================================================
"""


def main():

    logger.info("start main procedure")
    config_file: str = ""
    # Parse Arguments
    # doc : https://pymotw.com/2/argparse/
    parser = argparse.ArgumentParser(description='markdown to pdf converter')
    parser.add_argument('-f', help='config file, relative path from project', action="store", dest="config_file", required=False)
    parser.add_argument('-d', help='docs path, relative path from project', action="store", dest="docs_path", required=False)
    parser.add_argument('-p', help='project path', action="store", dest="project_path", required=False)
    parser.add_argument('-b', help='build path, relative path from project', action="store", dest="build_path", required=False)
    parser.add_argument('-l', help='Logging configuration File Name', action="store", dest="logging_config_filename", required=False,
                        default="logging.ini")
    parser.add_argument('-r', help='resource path, relative path from project', action="store", dest="resource_path", required=False)
    parser.add_argument('-o', help='pdf output file name, relative path from project', action="store", dest="output_filename", required=False)
    parser.add_argument('-s', help='site path, relative path from project', action="store", dest="site_path", required=False)
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    args = parser.parse_args()
    logger.debug(args)


    # load Logging configuration if file exists
    if os.path.exists(args.logging_config_filename):
        logging.config.fileConfig(args.logging_config_filename)

    logger.debug("last update: July 28, 2020, 08:47")
    t = Transform(config_filename=args.config_file, docs_path=args.docs_path, build_path=args.build_path,
                  project_path=args.project_path, resource_path=args.resource_path, output_filename=args.output_filename,
                  site_path=args.site_path)

    t.load_config()

    t.clean()

    t.open_file_combined()

    if t.do_get_git_history is True:
        t.get_git_history()

    t.create_menu()

    t.close_file_combined()

    t.create_mkdoc_conf_file()

    t.export_env()

    logger.info("end main procedure")


if __name__ == "__main__":
    main()
    logger.debug('end of program')
    quit()
