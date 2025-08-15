# LLM Assisted Database creation:

This project is a shiny app that allows the user to created databases
with the assistance of a LLM. This process consists of JSON schema
creation, selection of a representative sample with ground truth, prompt
engineering, validation on a random sample, and finally the creation of
the database.

<figure>
<img src="README/figure_1.jpg" alt="Figure 1: LLM Pipeline Schematic" />
<figcaption aria-hidden="true">Figure 1: LLM Pipeline
Schematic</figcaption>
</figure>

#### Who is this for?

This app is specialized for the extraction information from unstructured
text. Unstructured information that is too complex to extract with
regular expression typically requires manual extraction. This process is
slow and not without error. This pipeline allows for the exponential
gains in efficiency with statistically verifiable database accuracy.

#### What do I need?

The only required input is a large database of unstructured text from
which you wish to extract information with. This app requires specific
formatting for this text (which will be described in the the examples and
random sampling section).

# JSON Schema Creation:

This section allows you to creat your own json schema. A display of the
schema in its native format will be displayed on the right half of the
screen. This schema allows for the LLMS output to follow precise
formatting. When a schema is properly used, the output database requires
no cleaning and facilitate straight forward analysis. Every property should have
some level of formatting. Properties which are plain strings are high discouraged as any number 
of hallucinations of any length can be made. 

#### Name your schema:

Give you schema a name and give a description (no effect on output but
can be used for reference later so you know what the schema was about).

#### Object or Array:

Specify whether you want to extract one object from each unstructured
text or an array. Objects extract a single row of information from a
text, array extract numerous rows.

-   object: database of surgeon name, time, and EBL from a surgery
    report

    <table>
    <thead>
    <tr class="header">
    <th style="text-align: left;">surgeon_name</th>
    <th style="text-align: left;">time</th>
    <th style="text-align: left;">ebl_ml</th>
    </tr>
    </thead>
    <tbody>
    <tr class="odd">
    <td style="text-align: left;">Dr. Smith</td>
    <td style="text-align: left;">2024-08-12</td>
    <td style="text-align: left;">250</td>
    </tr>
    </tbody>
    </table>

-   array: all kidney lesions found in a radiology report

    <table>
    <thead>
    <tr class="header">
    <th style="text-align: left;">lesion_id</th>
    <th style="text-align: left;">location</th>
    <th style="text-align: left;">size_cm</th>
    <th style="text-align: left;">lesion_type</th>
    </tr>
    </thead>
    <tbody>
    <tr class="odd">
    <td style="text-align: left;">1</td>
    <td style="text-align: left;">left kidney</td>
    <td style="text-align: left;">2.3</td>
    <td style="text-align: left;">cyst</td>
    </tr>
    <tr class="even">
    <td style="text-align: left;">2</td>
    <td style="text-align: left;">right kidney</td>
    <td style="text-align: left;">1.5</td>
    <td style="text-align: left;">solid mass</td>
    </tr>
    <tr class="odd">
    <td style="text-align: left;">3</td>
    <td style="text-align: left;">left kidney</td>
    <td style="text-align: left;">0.9</td>
    <td style="text-align: left;">angiomyolipoma</td>
    </tr>
    </tbody>
    </table>

#### Object properties:

-   name: name of the property

-   type: string, number, integer

    -   string: free text that can have enumerations, format, or regex
        pattern or nothing restrictions at all.

        -   enumerations: list of possibe choices (`left`, `right`)

        -   format: predefined formats in Java: date-time
            (`2023-04-01T12:00:00Z`), date (`2023-04-01`), time
            (`14:30:00`), email (`user@example.com`), phone
            (`123-456-7891`), hostname (`www.example.com`), ipv4
            (`192.168.1.1`), ipv6 (`2001:0db8::1`), uri
            (`https://example.com`), uuid
            (`550e8400-e29b-41d4-a716-446655440000`), regex
            (`^[A-Z]{3}-\\d{4}$`), byte (`U29mdHdhcmU=`), binary
            (`01010101`), password (`masked input`)

        -   pattern: regex formats that aren’t supported by native json
            can be defined here. Of note, certain shorthands are not supported in r. All formats should start 
            with `^` and end with `$`. All `\` should be escaped as `\\`.
            `9.4 (ap) x 4.5 (ll)`, `9.4 (ap) x 4.5 (ll) x 5.2 (cc)`, or `9.4 x 5.4` could all be
            a valid output of:
            `^([0-9]+\\.[0-9]+( \\((ap|ll|cc)\\))?( ?x ?)?){1,3}$`.
            This is also a great way to make arrays of strings such as:
            `^(upper|mid|lower)? ?(medial|lateral)? ?(anterior|posterior|midline)?$`
            allowing a string of 1-3 location descriptors always in the
            same order- ie: `upper`, `posterior`, `upper lateral`,
            `mid lateral posterior`, but never `lateral upper`.

    -   number: any number format from integer, floating point, and
        exponential (`4`, `-5.2978`, `4e-5` all supported)

        -   enumerations: list of possible choices (`1`,`2`,`3`,`4`,`5`)

        -   minimum/ maximum: inclusive range by default.

    -   integer: integer specific number format (`1`,`2`,`3`,`4`,`5`)

-   required: If the item cannot be null, then check required. If the
    item can be null, do not check.

#### Add/Remove property

If you make a mistake you can add or remove a property. The property
added last will be removed. This can be repeated until all properties
are gone.

#### file name:

Enter file name for the schema to save as a .json file. Json files are
simply .txt files with specialized formatting. Minor errors can be
corrected in any text editor.

#### download the schema:

Download the schema you have created to use in the next steps.

# Selection of a Representative Sample

The next step is to select representative examples that will serve as
ground truth. There is no required number. A minimum of 20 examples is
advised; however, the more heterogeneous your data is the more examples
will be required to truly represent the complexity of the task. These
examples will be used to engineer a prompt. Prepare your examples by
placing them in the first column in an excel file. There should be no
columns names (data in A1:An with n examples).

#### input the .json file:

Upload your json schema you created in the previous step. This will auto
populate an example entry tab on the right half of the screen. Each
property will be pulled up as a form. Enumerations will be provided as a
drop down. Properties that allow null will populate a check box.

#### input an xlsx file:

Input at least 20 of your representative examples here as the xlsx file.
As a reminder: place examples in the first column in an excel file.
There should be no columns names (data in A1:An with n examples).

#### input the data:
Fill in the ground truth for each example. This information must be without error so be careful.

-   add row: After you have finished a data row click the `add row`
    button. `Preview` will give you a visual of the data frame as well
    as a json validation message based on your schema. `Valid` rows
    match the schema rules, `Invalid` rows failed validation. The
    specific invalid datapoint(s) will be bookend by question marks
    (`?left?`). For array schemas, you can add multiple rows for each
    example. For object types you can only add one.

-   remove row: removed the last entry and clear the validation logic.
    Redo the entry and it will be revalidated.

#### arrows:

Move forward or backward from each example. The json data and validation
will be saved for each example.

#### File names:

Enter file names without extensions.

#### download .rds:

Download the RDS file to use in the next step. There will be an
`example` column and a `data` column with a nested data frame of object
properties. This will be used for automating accuracy calculations for
prompt engineering.

#### download .xslx: 

Downloaded the examples as a unnested .xslx file.
This is commonly used to visualize the examples for accuracy. Note,
exporting to excel can mess with formats such as dates.

# Prompt Engineering

In the next phase you will engineer a prompt based on your representative examples. Inputs for this
phase are the JSON engineered in the first phase, the representative examples as a .rds file, and a valid 
BIOHPC node. Enter the node address in the format `abc.de.fgh.ij`. 

#### ID Column

When you have an array schema, and ID column is usually required. This assigns an ID to each row and allows
for a comparison to a ground truth irregardless of the order of the rows. Object schema do not usually contain 
an ID columns and are just compared by the `examples` column. The id column is the by-variable used for 
comparison within each example.

#### BIOHPC Node

Enter you assigned BIOHPC node in the format `abc.de.fgh.ij`. If the address is valid, you will be able to 
choose from one of the available LLMs.

#### Model

Choose the LLM you would like to use for your task. Each model is trained on different data sets and thus will
give different outputs for the same prompt.


#### Context Window

Enter the context window for the model based on your prompt and example legnth. A suggested minimum context 
legnth is given based on the longest example provided and your prompt. The formula used is: 
`context window = (word count of largest example + prompt) x (0.75)`.

#### Prompt

Based on you examples, a prompt template will be generated. The prompt will give the added context and 
instructions for the LLM to complete your task. This prompt will be incrementally tweaked to increase the 
predicted accuracy. 


  - General:  A `General` text box will be populated for any task. In `General` you should provide the 
  overview and relevant background information for you task. Finish every general prompt with the phrase 
  `return as JSON` as this will cut down processing time. 

  - Properties: Each property of an object will have its own prompt text box generated. Each property can be 
  individually engineered to increase its accuracy. Any JSON formatting, enumerations, ranges etc. should be 
  repeated in the property prompt to assist with processing time. Additionally any added context for an 
  individual property should be added.
  
#### Analysis

After you submit each prompt you will be able to instantly asses the models performance. This performance is 
to be analyzed to incrementally tweak the prompt to a high accuracy. An accuracy ~ 95% is generally 
recommended for most purposes.

  - Average time: The average time per inference will be displayed. As a general rule, the faster your 
  inference the more straightforward your task and prompt is. This can very widely based on GPU performance. 
  However, this is just another tool to analyze the methods. Prompts with identical accuracy can be chosen 
  based on inference time to improve efficiency.
  
  - Observations: Essentially how many rows in the output database. For object schema this will be the 
  number of examples, for arrays this can be any number. The number of hallucinated or omitted objects will 
  also be displayed. Hallucinated objects are objects not present in the ground truth and omitted objects are 
  not present in the LLM output. Hallucinations and omissions generally apply for array schema only.
  
  - Variable accuracy: For each property the accuracy will be calculated according to the formula: 
  `Variable accuracy = [(n correct values for a property) / (n observations in LLM output)] * 100`
  Of note, omitted observations have no effect on the accuracy of an individual property. This is because when
  the LLM decides not to include an object in an array there is now way to analyze the correctness of the 
  hypothetical property. Further, the omission of an object is rarely due to the prompt of individual 
  properties. 
  
  - Total Accuracy: For each prompt the total accuracy will be calculated according to the formula:
  `Total Accuracy = 100 - [(n incorrect values in the database) + (n omitted objects)(n properties)]/[n total data points in the ground truth]`
  The total accuracy of a prompt includes omissions.
  
#### Download Prompt

Once the predicted accuracy on the representative sample is sufficiently high (~95%), the prompt can be downloaded 
as a .txt file for future use. 

# Random sampling/ Running the whole batch

As the prompt was progressively engineered on a small sample, it's possible the prompt over fits to the sample and does
not represent the true accuracy of the prompt for the given task. Thus the prompt needs to be validated on a 
random sample. Any changes to the prompt need to be re validated with an new random sample. 

#### Upload Schema, Prompt, and Batch

Upload the the schema and prompt that was just engineered. Then upload your batch as an .xlsx file and select the 
column that contains the unstructured text that needs to be extracted. 

#### Sample Size/ Full runs

Select the sample size of the random sample size for validation. Samples ~100 are usually sufficient, however this 
can very based on the predicted accuracy and your threshold accuracy. To run the full task, simply ingore this input.

#### IP Address/Model/Context Window

Input these parameters as you have done in the prompt engineering step. The context window will be suggested based on 
the longest input in the sample/ full run. 

#### Submit your query

Submit your query to the llm, the progress of the task will be displayed. After the task has finished, the output 
can be downloaded for validation or analysis. 

# Example 1: Extraction of Kidney Lesions form radiology reports

# Example 2: Extraction of Kidney Lesions form pathology reports
